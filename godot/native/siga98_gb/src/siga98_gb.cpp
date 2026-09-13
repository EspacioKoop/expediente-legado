#include "siga98_gb.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

extern "C" {
#include "peanut_gb.h"
}

namespace godot {

namespace {
constexpr int FRAME_WIDTH = 160;
constexpr int FRAME_HEIGHT = 144;
constexpr int FRAME_CHANNELS = 4;
constexpr int MIN_ROM_SIZE = 32 * 1024;
constexpr int MAX_ROM_SIZE = 8 * 1024 * 1024;
constexpr uint8_t CGB_ONLY_FLAG = 0xC0;
constexpr int CGB_FLAG_OFFSET = 0x143;
constexpr int TITLE_START = 0x134;
constexpr int TITLE_END = 0x143;
} // namespace

struct Siga98GB::Impl {
    gb_s gb{};
    std::vector<uint8_t> rom;
    std::vector<uint8_t> cart_ram;
    std::array<uint8_t, FRAME_WIDTH * FRAME_HEIGHT * FRAME_CHANNELS> frame{};
    bool loaded = false;
    bool runtime_error = false;
    std::string title;
    std::string error;
};

static Siga98GB::Impl *priv(gb_s *p_gb) {
    return static_cast<Siga98GB::Impl *>(p_gb->direct.priv);
}

static uint8_t read_rom(gb_s *p_gb, const uint_fast32_t p_addr) {
    const Siga98GB::Impl *p = priv(p_gb);
    if (p == nullptr || p_addr >= p->rom.size()) {
        return 0xFF;
    }
    return p->rom[p_addr];
}

static uint8_t read_cart_ram(gb_s *p_gb, const uint_fast32_t p_addr) {
    const Siga98GB::Impl *p = priv(p_gb);
    if (p == nullptr || p_addr >= p->cart_ram.size()) {
        return 0xFF;
    }
    return p->cart_ram[p_addr];
}

static void write_cart_ram(gb_s *p_gb, const uint_fast32_t p_addr, const uint8_t p_value) {
    Siga98GB::Impl *p = priv(p_gb);
    if (p != nullptr && p_addr < p->cart_ram.size()) {
        p->cart_ram[p_addr] = p_value;
    }
}

static void emulator_error(gb_s *p_gb, const gb_error_e p_error, const uint16_t p_addr) {
    Siga98GB::Impl *p = priv(p_gb);
    if (p == nullptr) {
        return;
    }
    p->runtime_error = true;
    p->error = "Peanut-GB runtime error " + std::to_string(static_cast<int>(p_error)) +
            " at 0x";
    constexpr char hex[] = "0123456789ABCDEF";
    for (int shift = 12; shift >= 0; shift -= 4) {
        p->error.push_back(hex[(p_addr >> shift) & 0x0F]);
    }
}

static void draw_line(gb_s *p_gb, const uint8_t p_pixels[FRAME_WIDTH],
        const uint_fast8_t p_line) {
    Siga98GB::Impl *p = priv(p_gb);
    if (p == nullptr || p_line >= FRAME_HEIGHT) {
        return;
    }

    static constexpr uint8_t palette[4][3] = {
        {224, 232, 196},
        {164, 184, 132},
        {84, 112, 76},
        {24, 38, 30},
    };
    for (int x = 0; x < FRAME_WIDTH; ++x) {
        const uint8_t shade = p_pixels[x] & 0x03;
        const size_t offset = (static_cast<size_t>(p_line) * FRAME_WIDTH + x) * FRAME_CHANNELS;
        p->frame[offset] = palette[shade][0];
        p->frame[offset + 1] = palette[shade][1];
        p->frame[offset + 2] = palette[shade][2];
        p->frame[offset + 3] = 255;
    }
}

Siga98GB::Siga98GB() : impl(std::make_unique<Impl>()) {}

Siga98GB::~Siga98GB() = default;

void Siga98GB::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_rom", "rom"), &Siga98GB::load_rom);
    ClassDB::bind_method(D_METHOD("reset"), &Siga98GB::reset);
    ClassDB::bind_method(D_METHOD("is_loaded"), &Siga98GB::is_loaded);
    ClassDB::bind_method(D_METHOD("set_buttons", "buttons"), &Siga98GB::set_buttons);
    ClassDB::bind_method(D_METHOD("run_frame_rgba"), &Siga98GB::run_frame_rgba);
    ClassDB::bind_method(D_METHOD("rom_title"), &Siga98GB::rom_title);
    ClassDB::bind_method(D_METHOD("last_error"), &Siga98GB::last_error);
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
    if (size < MIN_ROM_SIZE || size <= CGB_FLAG_OFFSET) {
        impl->error = "ROM demasiado pequeña";
        return LOAD_TOO_SMALL;
    }
    if (size > MAX_ROM_SIZE) {
        impl->error = "ROM demasiado grande";
        return LOAD_TOO_LARGE;
    }
    if (p_rom[CGB_FLAG_OFFSET] == CGB_ONLY_FLAG) {
        impl->error = "ROM CGB-only no soportada por el núcleo DMG";
        return LOAD_CGB_ONLY;
    }

    impl->rom.resize(static_cast<size_t>(size));
    std::memcpy(impl->rom.data(), p_rom.ptr(), static_cast<size_t>(size));

    const int init_result = static_cast<int>(gb_init(
            &impl->gb, &read_rom, &read_cart_ram, &write_cart_ram, &emulator_error, impl.get()));
    if (init_result != static_cast<int>(GB_INIT_NO_ERROR)) {
        impl->error = "ROM rechazada por Peanut-GB: " + std::to_string(init_result);
        impl->rom.clear();
        return LOAD_INVALID_ROM;
    }

    size_t save_size = 0;
    if (gb_get_save_size_s(&impl->gb, &save_size) < 0) {
        impl->error = "Tamaño de SRAM inválido";
        impl->rom.clear();
        return LOAD_INVALID_SAVE;
    }
    impl->cart_ram.assign(save_size, 0);
    gb_init_lcd(&impl->gb, &draw_line);
    impl->gb.direct.joypad = 0xFF;
    impl->frame.fill(0);

    impl->title.clear();
    for (int index = TITLE_START; index < TITLE_END; ++index) {
        const uint8_t value = impl->rom[static_cast<size_t>(index)];
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
    const uint8_t pressed = static_cast<uint8_t>(p_buttons & 0xFF);
    impl->gb.direct.joypad = static_cast<uint8_t>(~pressed);
}

PackedByteArray Siga98GB::run_frame_rgba() {
    PackedByteArray result;
    if (!impl->loaded) {
        return result;
    }

    impl->runtime_error = false;
    gb_run_frame(&impl->gb);
    if (impl->runtime_error) {
        impl->loaded = false;
        return result;
    }

    result.resize(static_cast<int64_t>(impl->frame.size()));
    std::memcpy(result.ptrw(), impl->frame.data(), impl->frame.size());
    return result;
}

String Siga98GB::rom_title() const {
    return String::utf8(impl->title.c_str());
}

String Siga98GB::last_error() const {
    return String::utf8(impl->error.c_str());
}

int Siga98GB::width() const {
    return FRAME_WIDTH;
}

int Siga98GB::height() const {
    return FRAME_HEIGHT;
}

} // namespace godot
