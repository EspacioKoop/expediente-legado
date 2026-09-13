#pragma once

#include <memory>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class Siga98GB : public RefCounted {
    GDCLASS(Siga98GB, RefCounted)

public:
    enum LoadResult {
        LOAD_OK = 0,
        LOAD_TOO_SMALL = 1,
        LOAD_TOO_LARGE = 2,
        LOAD_CGB_ONLY = 3,
        LOAD_INVALID_ROM = 4,
        LOAD_INVALID_SAVE = 5,
        LOAD_RUNTIME_ERROR = 6,
    };

    Siga98GB();
    ~Siga98GB() override;

    int load_rom(const PackedByteArray &p_rom);
    void reset();
    bool is_loaded() const;
    void set_buttons(int64_t p_buttons);
    PackedByteArray run_frame_rgba();
    String rom_title() const;
    String last_error() const;
    int width() const;
    int height() const;

protected:
    static void _bind_methods();

private:
    struct Impl;
    std::unique_ptr<Impl> impl;
};

} // namespace godot

VARIANT_ENUM_CAST(godot::Siga98GB::LoadResult);
