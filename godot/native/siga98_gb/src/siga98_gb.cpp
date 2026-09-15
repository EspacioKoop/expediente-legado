#include "siga98_gb.h"

#include <array>
#include <cctype>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

extern "C" {
#include "Core/gb.h"
}

// Generado por SConstruct desde la boot ROM libre de SameBoy (cgb_boot_fast.asm,
// Expat). No es la BIOS de Nintendo.
#include "sameboy_cgb_boot.h"

namespace godot {

namespace {
constexpr int FRAME_WIDTH = 160;
constexpr int FRAME_HEIGHT = 144;
constexpr int FRAME_CHANNELS = 4;
constexpr int MIN_ROM_SIZE = 32 * 1024;
constexpr int MAX_ROM_SIZE = 8 * 1024 * 1024;
constexpr int HEADER_CHECKSUM_OFFSET = 0x14D;
constexpr int HEADER_START = 0x134;
constexpr int HEADER_END = 0x14C;
constexpr int TITLE_START = 0x134;
constexpr int TITLE_END = 0x143;
constexpr unsigned AUDIO_SAMPLE_RATE = 48000;
constexpr size_t AUDIO_BYTES_PER_FRAME = 4; // S16LE estéreo.
constexpr size_t MAX_AUDIO_BUFFER_BYTES = AUDIO_SAMPLE_RATE * AUDIO_BYTES_PER_FRAME;

// Contrato público de set_buttons (heredado de Peanut-GB): A, B, Select, Start,
// Derecha, Izquierda, Arriba, Abajo en los bits 0..7.
constexpr GB_key_t BUTTON_KEYS[8] = {
    GB_KEY_A, GB_KEY_B, GB_KEY_SELECT, GB_KEY_START,
    GB_KEY_RIGHT, GB_KEY_LEFT, GB_KEY_UP, GB_KEY_DOWN,
};
} // namespace

struct Siga98GB::Impl {
    GB_gameboy_t *gb = nullptr;
    std::array<uint32_t, FRAME_WIDTH * FRAME_HEIGHT> pixels{};
    std::vector<uint8_t> audio_pcm;
    bool loaded = false;
    std::string title;
    std::string error;

    ~Impl() {
        if (gb != nullptr) {
            GB_apu_set_sample_callback(gb, nullptr);
            GB_set_user_data(gb, nullptr);
            GB_free(gb);
            GB_dealloc(gb);
        }
    }
};

static void load_boot_rom(GB_gameboy_t *p_gb, GB_boot_rom_t p_type) {
    (void)p_type;
    GB_load_boot_rom_from_buffer(p_gb, SAMEBOY_CGB_BOOT, sizeof(SAMEBOY_CGB_BOOT));
}

// Empaqueta RGBA en orden de bytes little-endian para copiar el framebuffer tal cual.
static uint32_t encode_rgba(GB_gameboy_t *p_gb, uint8_t p_r, uint8_t p_g, uint8_t p_b) {
    (void)p_gb;
    return 0xFF000000u | (static_cast<uint32_t>(p_b) << 16) |
            (static_cast<uint32_t>(p_g) << 8) | p_r;
}

static void discard_log(GB_gameboy_t *p_gb, const char *p_string, GB_log_attributes_t p_attributes) {
    (void)p_gb;
    (void)p_string;
    (void)p_attributes;
}

static void append_s16le(std::vector<uint8_t> &p_buffer, int16_t p_sample) {
    const uint16_t bits = static_cast<uint16_t>(p_sample);
    p_buffer.push_back(static_cast<uint8_t>(bits & 0xFF));
    p_buffer.push_back(static_cast<uint8_t>((bits >> 8) & 0xFF));
}

static void capture_audio_sample(GB_gameboy_t *p_gb, GB_sample_t *p_sample) {
    if (p_gb == nullptr || p_sample == nullptr) {
        return;
    }
    auto *impl = static_cast<Siga98GB::Impl *>(GB_get_user_data(p_gb));
    if (impl == nullptr || impl->audio_pcm.size() + AUDIO_BYTES_PER_FRAME > MAX_AUDIO_BUFFER_BYTES) {
        return;
    }
    append_s16le(impl->audio_pcm, p_sample->left);
    append_s16le(impl->audio_pcm, p_sample->right);
}

Siga98GB::Siga98GB() : impl(std::make_unique<Impl>()) {}

Siga98GB::~Siga98GB() = default;

void Siga98GB::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_rom", "rom"), &Siga98GB::load_rom);
    ClassDB::bind_method(D_METHOD("reset"), &Siga98GB::reset);
    ClassDB::bind_method(D_METHOD("is_loaded"), &Siga98GB::is_loaded);
    ClassDB::bind_method(D_METHOD("set_buttons", "buttons"), &Siga98GB::set_buttons);
    ClassDB::bind_method(D_METHOD("run_frame_rgba"), &Siga98GB::run_frame_rgba);
    ClassDB::bind_method(D_METHOD("drain_audio_pcm16"), &Siga98GB::drain_audio_pcm16);
    ClassDB::bind_method(D_METHOD("audio_sample_rate"), &Siga98GB::audio_sample_rate);
    ClassDB::bind_method(D_METHOD("save_ram"), &Siga98GB::save_ram);
    ClassDB::bind_method(D_METHOD("load_save_ram", "save"), &Siga98GB::load_save_ram);
    ClassDB::bind_method(D_METHOD("read_memory_u8", "address"), &Siga98GB::read_memory_u8);
    ClassDB::bind_method(D_METHOD("rom_title"), &Siga98GB::rom_title);
    ClassDB::bind_method(D_METHOD("last_error"), &Siga98GB::last_error);
    ClassDB::bind_method(D_METHOD("core_name"), &Siga98GB::core_name);
    ClassDB::bind_method(D_METHOD("supports_cgb"), &Siga98GB::supports_cgb);
    ClassDB::bind_method(D_METHOD("supports_audio"), &Siga98GB::supports_audio);
    ClassDB::bind_method(D_METHOD("width"), &Siga98GB::width);
    ClassDB::bind_method(D_METHOD("height"), &Siga98GB::height);

    BIND_ENUM_CONSTANT(LOAD_OK);
    BIND_ENUM_CONSTANT(LOAD_TOO_SMALL);
    BIND_ENUM_CONSTANT(LOAD_TOO_LARGE);
    BIND_ENUM_CONSTANT(LOAD_CGB_ONLY);
    BIND_ENUM_CONSTANT(LOAD_INVALID_ROM);
    BIND_ENUM_CONSTANT(LOAD_INVALID_SAVE);
    BIND_ENUM_CONSTANT(LOAD_RUNTIME_ERROR);
}

int Siga98GB::load_rom(const PackedByteArray &p_rom) {
    reset();
    const int64_t size = p_rom.size();
    if (size < MIN_ROM_SIZE) {
        impl->error = "ROM demasiado pequeña";
        return LOAD_TOO_SMALL;
    }
    if (size > MAX_ROM_SIZE) {
        impl->error = "ROM demasiado grande";
        return LOAD_TOO_LARGE;
    }

    const uint8_t *rom = p_rom.ptr();
    uint8_t checksum = 0;
    for (int index = HEADER_START; index <= HEADER_END; ++index) {
        checksum = static_cast<uint8_t>(checksum - rom[index] - 1);
    }
    if (checksum != rom[HEADER_CHECKSUM_OFFSET]) {
        impl->error = "Cabecera de ROM inválida";
        return LOAD_INVALID_ROM;
    }

    impl->gb = GB_init(GB_alloc(), GB_MODEL_CGB_E);
    if (impl->gb == nullptr) {
        impl->error = "No se pudo inicializar SameBoy";
        return LOAD_RUNTIME_ERROR;
    }
    GB_set_log_callback(impl->gb, &discard_log);
    GB_set_boot_rom_load_callback(impl->gb, &load_boot_rom);
    GB_set_rgb_encode_callback(impl->gb, &encode_rgba);
    GB_set_pixels_output(impl->gb, impl->pixels.data());
    GB_set_color_correction_mode(impl->gb, GB_COLOR_CORRECTION_MODERN_BALANCED);
    GB_set_user_data(impl->gb, impl.get());
    GB_apu_set_sample_callback(impl->gb, &capture_audio_sample);
    GB_set_sample_rate(impl->gb, AUDIO_SAMPLE_RATE);
    GB_load_rom_from_buffer(impl->gb, rom, static_cast<size_t>(size));
    GB_reset(impl->gb);

    impl->title.clear();
    for (int index = TITLE_START; index < TITLE_END; ++index) {
        const uint8_t value = rom[index];
        if (value == 0) {
            break;
        }
        impl->title.push_back(std::isprint(value) ? static_cast<char>(value) : '?');
    }
    impl->loaded = true;
    impl->error.clear();
    return LOAD_OK;
}

void Siga98GB::reset() {
    impl = std::make_unique<Impl>();
}

bool Siga98GB::is_loaded() const {
    return impl->loaded;
}

void Siga98GB::set_buttons(const int64_t p_buttons) {
    if (!impl->loaded) {
        return;
    }
    for (int bit = 0; bit < 8; ++bit) {
        GB_set_key_state(impl->gb, BUTTON_KEYS[bit], (p_buttons >> bit) & 1);
    }
}

PackedByteArray Siga98GB::run_frame_rgba() {
    PackedByteArray result;
    if (!impl->loaded) {
        return result;
    }

    GB_run_frame(impl->gb);
    const size_t bytes = impl->pixels.size() * FRAME_CHANNELS;
    result.resize(static_cast<int64_t>(bytes));
    std::memcpy(result.ptrw(), impl->pixels.data(), bytes);
    return result;
}

PackedByteArray Siga98GB::drain_audio_pcm16() {
    PackedByteArray result;
    if (impl->audio_pcm.empty()) {
        return result;
    }
    result.resize(static_cast<int64_t>(impl->audio_pcm.size()));
    std::memcpy(result.ptrw(), impl->audio_pcm.data(), impl->audio_pcm.size());
    impl->audio_pcm.clear();
    return result;
}

int Siga98GB::audio_sample_rate() const {
    return static_cast<int>(AUDIO_SAMPLE_RATE);
}

PackedByteArray Siga98GB::save_ram() const {
    PackedByteArray result;
    if (!impl->loaded) {
        return result;
    }
    const int size = GB_save_battery_size(impl->gb);
    if (size <= 0) {
        return result;
    }
    result.resize(size);
    GB_save_battery_to_buffer(impl->gb, result.ptrw(), static_cast<size_t>(size));
    return result;
}

bool Siga98GB::load_save_ram(const PackedByteArray &p_save) {
    if (!impl->loaded) {
        impl->error = "No hay ROM cargada para restaurar SRAM";
        return false;
    }
    if (p_save.size() != GB_save_battery_size(impl->gb)) {
        impl->error = "Tamaño de SRAM no coincide con el cartucho";
        return false;
    }
    if (p_save.size() > 0) {
        GB_load_battery_from_buffer(impl->gb, p_save.ptr(), static_cast<size_t>(p_save.size()));
    }
    impl->error.clear();
    return true;
}

int Siga98GB::read_memory_u8(const int64_t p_address) const {
    if (!impl->loaded || impl->gb == nullptr || p_address < 0 || p_address > 0xFFFF) {
        return -1;
    }
    return static_cast<int>(GB_safe_read_memory(impl->gb, static_cast<uint16_t>(p_address)));
}

String Siga98GB::rom_title() const {
    return String::utf8(impl->title.c_str());
}

String Siga98GB::last_error() const {
    return String::utf8(impl->error.c_str());
}

String Siga98GB::core_name() const {
    return "SameBoy";
}

bool Siga98GB::supports_cgb() const {
    return true;
}

bool Siga98GB::supports_audio() const {
    return true;
}

int Siga98GB::width() const {
    return FRAME_WIDTH;
}

int Siga98GB::height() const {
    return FRAME_HEIGHT;
}

} // namespace godot
