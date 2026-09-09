#!/usr/bin/env python3
"""Статическая проверка GML-исходников VetSim.

GameMaker IDE в песочнице нет, поэтому проверяем то, что можно
проверить без компилятора:

  1. баланс скобок {} () [] вне строк и комментариев;
  2. каждый вызов foo(...) ссылается на функцию, объявленную в проекте
     (или на известный встроенный символ GameMaker);
  3. в файлах не осталось полей старой схемы клиник;
  4. каждый изменённый файл использует только макросы, объявленные
     в проекте.

Запуск:  python3 tools/gml_check.py
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SKIP_DIRS = {".git", "docs", "options", "sprites", "fonts", "tilesets",
             "shaders", "tools"}

# ── Встроенные функции и константы GameMaker, которые используются в проекте ──
BUILTIN = set("""
array_length array_push array_delete array_create array_insert
is_struct is_array is_real is_string is_bool is_undefined is_method
variable_global_exists variable_instance_exists variable_struct_exists
variable_struct_get variable_struct_set variable_struct_remove
variable_struct_get_names variable_struct_names_count
string int64 real bool round floor ceil clamp abs min max sign
irandom random randomize choose median mean
asset_get_index script_exists object_exists instance_exists room_exists
sprite_exists font_exists
instance_number instance_find instance_destroy instance_place
instance_position instance_nearest instance_farthest
point_in_rectangle point_in_circle point_distance point_direction
lengthdir_x lengthdir_y
mp_grid_create mp_grid_destroy mp_grid_add_instances mp_grid_path
mp_grid_add_cell mp_grid_clear_all
room_goto room_goto_previous room_restart room_width room_height
game_get_speed gamespeed_fps
show_debug_message show_message
draw_set_color draw_set_alpha draw_set_halign draw_set_valign
draw_rectangle draw_roundrect draw_roundrect_ext draw_circle draw_set_circle_precision draw_arc draw_line draw_primitive_begin draw_vertex draw_primitive_end
draw_line draw_line_width draw_triangle draw_text draw_text_transformed
draw_sprite draw_sprite_ext draw_sprite_stretched
draw_surface draw_surface_ext draw_getpixel
string_width string_height string_width_ext string_height_ext
string_length string_copy string_pos string_replace string_replace_all
string_upper string_lower string_digits string_format
display_get_gui_width display_get_gui_height
surface_create surface_free surface_set_target surface_reset_target
surface_exists surface_get_width surface_get_height surface_copy
surface_resize surface_set_target application_surface
device_mouse_x_to_gui device_mouse_y_to_gui device_mouse_x device_mouse_y
mouse_check_button mouse_check_button_pressed mouse_check_button_released
mouse_wheel_up mouse_wheel_down mouse_x mouse_y
device_mouse_check_button device_mouse_check_button_pressed
device_mouse_check_button_released device_mouse_dbclick
keyboard_check keyboard_check_pressed keyboard_check_released
camera_get_view_x camera_get_view_y camera_get_view_width
camera_get_view_height camera_set_view_pos camera_set_view_size
view_camera view_visible view_xport view_yport view_wport view_hport
make_color_rgb make_color_hsv color_get_red color_get_green color_get_blue
merge_color draw_get_color c_white c_black c_red c_green c_blue c_yellow
c_gray c_dkgray c_ltgray c_orange c_maroon c_purple c_teal c_navy
c_silver c_olive c_lime c_aqua c_fuchsia
fa_left fa_right fa_center fa_top fa_bottom fa_middle
mb_left mb_right mb_middle mb_none
bm_normal bm_add bm_subtract bm_max bm_zero bm_one bm_src_alpha
bm_inv_src_alpha bm_dest_alpha bm_inv_dest_alpha
pr_trianglelist pr_linelist
sprite_get_name sprite_get_width sprite_get_height object_get_name
sprite_get_xoffset sprite_get_yoffset
json_stringify json_parse
ds_list_create ds_list_destroy ds_list_add ds_list_size ds_list_find_value
ds_map_create ds_map_destroy ds_map_add ds_map_find_value
os_browser os_type
room_get_name room_get_viewport
instance_create_layer instance_create_depth instance_destroy
irandom_range random_range randomise
array_contains array_pop array_sort array_shuffle array_resize
buffer_create buffer_delete buffer_read buffer_write buffer_save
buffer_load buffer_seek buffer_tell buffer_get_size
collision_circle collision_rectangle collision_point collision_line
cos sin tan dcos dsin dtan arccos arcsin arctan arctan2 degtorad radtodeg
power sqr sqrt exp ln log2 log10
display_reset display_set_timing_method display_get_timing_method
display_set_sleep_margin display_get_sleep_margin display_get_frequency
game_set_speed game_restart game_end game_save game_load
window_has_focus window_get_width window_get_height window_set_caption
draw_set_font draw_get_font draw_get_halign draw_get_valign
draw_clear_alpha draw_ellipse draw_ellipse_color
draw_primitive_begin draw_primitive_end draw_vertex draw_vertex_color
draw_self draw_sprite_general draw_text_ext draw_text_ext_transformed
ds_exists ds_list_clear ds_list_delete ds_list_find_index ds_list_insert
ds_list_sort ds_list_shuffle ds_list_empty ds_list_copy
ds_map_delete ds_map_exists ds_map_find_first ds_map_find_next
ds_map_clear ds_map_empty ds_map_size
event_inherited event_perform event_perform_object event_user
file_delete file_exists file_text_open_read file_text_close
gpu_set_scissor shader_get_uniform shader_reset shader_set
shader_set_uniform_f shader_set_uniform_matrix
mp_grid_clear_cell mp_grid_draw mp_grid_get_cell
move_towards_point object_is_ancestor ord chr
path_add path_delete path_end path_exists path_get_length
path_get_x path_get_y path_set_kind path_start
sprite_create_from_surface sprite_get_uvs sprite_get_texture
string_byte_length string_char_at string_delete string_insert
variable_global_get variable_global_set
variable_instance_get variable_instance_set variable_instance_get_names
audio_play_sound audio_stop_sound audio_sound_gain
sprite_add sprite_delete sprite_replace
matrix_build matrix_multiply matrix_transform_vertex
gpu_set_blendmode gpu_set_alphatestenable
texture_prefetch
math_set_epsilon
lerp dot_product
gpu_set_fog
texture_get_width
sprite_get_number
draw_clear
screen_save
window_device
browser_input_capture
""".split())

BUILTIN_VARS = set("""
room speed fps game_speed image_xscale image_yscale image_angle
image_index image_speed x y direction speed hspeed vspeed visible
depth object_index id sprite_index mask_index solid persistent
bbox_left bbox_right bbox_top bbox_bottom path_index path_position
path_speed alarm timeline_index timeline_position timeline_speed
phy_position_x phy_position_y keyboard_key mouse_button
instance_count debug_mode argument_count argument argument0
other self global local
""".split())


def gml_files():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name.endswith(".gml"):
                yield os.path.join(dirpath, name)


def strip_code(text, keep_strings=False):
    """Убирает комментарии, а строки заменяет пустыми.

    Возвращает текст той же длины, чтобы номера строк совпадали.
    При keep_strings=True содержимое строк сохраняется — это нужно
    интерпретатору, который проверяет логику на реальных ключах
    структур ("rooms", "reputation" и так далее).
    """
    out = []
    i = 0
    n = len(text)

    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""

        if c == "/" and nxt == "/":
            j = text.find("\n", i)
            j = n if j == -1 else j
            out.append(" " * (j - i))
            i = j
        elif c == "/" and nxt == "*":
            j = text.find("*/", i + 2)
            j = n if j == -1 else j + 2
            chunk = text[i:j]
            out.append("".join("\n" if ch == "\n" else " " for ch in chunk))
            i = j
        elif c in "\"'":
            quote = c
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == quote:
                    j += 1
                    break
                if text[j] == "\n":
                    break
                j += 1
            # Закрывающую кавычку тоже выводим: без неё текст становился
            # на символ короче исходного (номера строк съезжали), а при
            # повторном проходе «открывалась» новая строка.
            inner = max(0, j - i - 2)

            if keep_strings:
                content = text[i + 1:i + 1 + inner]
                out.append(quote + content + quote)
            else:
                out.append(quote + " " * inner + quote)

            i = j
        else:
            out.append(c)
            i += 1

    return "".join(out)


FUNC_DEF = re.compile(r"^\s*function\s+([A-Za-z_]\w*)\s*\(", re.M)
# Методы экземпляров: `name = function(` внутри Create/Step объектов и
# `function name()` в теле другого метода. В отчёт попадать не должны.
METHOD_DEF = re.compile(r"\b([A-Za-z_]\w*)\s*=\s*function\s*\(")
NESTED_FUNC = re.compile(r"\bfunction\s+([A-Za-z_]\w*)\s*\(")
FUNC_CALL = re.compile(r"(?<![.\w#])([A-Za-z_]\w*)\s*\(")

# Макросы, объявленные в файле проекта .yyp (в репозиторий он не входит).
PROJECT_MACROS = {
    "RESTOCK_BATCH", "RESTOCK_TARGET", "RESTOCK_MIN_GAP", "RESTOCK_MAX",
    "PLAYER_CARRY_MAX", "STUCK_THRESHOLD",
}

ENUM_DEF = re.compile(r"\benum\s+([A-Za-z_]\w*)", re.M)
ENUM_MEMBER = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\s*(?:=|,|$)", re.M)
MACRO_DEF = re.compile(r"^\s*#macro\s+([A-Za-z_]\w*)", re.M)
IDENT = re.compile(r"\b([A-Za-z_]\w*)\b")

# Слова, после которых скобка — не вызов функции.
KEYWORDS = {
    "if", "while", "for", "switch", "with", "repeat", "return", "do",
    "function", "case", "catch", "until", "and", "or", "not", "mod",
    "div", "xor", "else",
}


def collect_definitions():
    defined = set()
    macros = set()

    for path in gml_files():
        with open(path, encoding="utf-8", errors="replace") as handle:
            raw = handle.read()

        code = strip_code(raw)

        for match in FUNC_DEF.finditer(code):
            defined.add(match.group(1))

        for match in MACRO_DEF.finditer(raw):
            macros.add(match.group(1))

        # Имена enum и их члены — не макросы, но записываются капсом.
        for match in ENUM_DEF.finditer(code):
            macros.add(match.group(1))

        for match in ENUM_MEMBER.finditer(code):
            macros.add(match.group(1))

        for match in METHOD_DEF.finditer(code):
            defined.add(match.group(1))

        for match in NESTED_FUNC.finditer(code):
            defined.add(match.group(1))

    return defined, macros


def main():
    defined, macros = collect_definitions()

    problems = []
    checked = 0

    for path in gml_files():
        rel = os.path.relpath(path, ROOT)

        with open(path, encoding="utf-8", errors="replace") as handle:
            raw = handle.read()

        code = strip_code(raw)
        checked += 1

        # ── 1. Баланс скобок ──
        pairs = {"}": "{", ")": "(", "]": "["}
        stack = []

        for line_no, line in enumerate(code.split("\n"), start=1):
            for col, ch in enumerate(line, start=1):
                if ch in "{([":
                    stack.append((ch, line_no, col))
                elif ch in "})]":
                    if not stack:
                        problems.append(
                            "%s:%d:%d лишняя закрывающая %r" % (rel, line_no, col, ch)
                        )
                    else:
                        open_ch, oline, ocol = stack.pop()
                        if open_ch != pairs[ch]:
                            problems.append(
                                "%s:%d:%d %r закрывает %r из %s:%d:%d"
                                % (rel, line_no, col, ch, open_ch, rel, oline, ocol)
                            )

        for open_ch, line_no, col in stack:
            problems.append(
                "%s:%d:%d незакрытая %r" % (rel, line_no, col, open_ch)
            )

        # Локальные вспомогательные функции файла (например, _shelf_draw_quad).
        local_names = set(METHOD_DEF.findall(code)) | set(NESTED_FUNC.findall(code))

        # ── 2. Неизвестные функции ──
        for match in FUNC_CALL.finditer(code):
            name = match.group(1)

            if name in KEYWORDS or name in BUILTIN or name in defined:
                continue

            if name in local_names:
                continue

            line_no = code.count("\n", 0, match.start()) + 1
            problems.append(
                "%s:%d вызов неизвестной функции %s()" % (rel, line_no, name)
            )

        # ── 3. Неизвестные макросы (CAPS_WITH_UNDERSCORES) ──
        for match in IDENT.finditer(code):
            name = match.group(1)

            if not (name.isupper() and "_" in name):
                continue

            if name in macros or name in BUILTIN or name in PROJECT_MACROS:
                continue

            # Локальная переменная с подчёркиванием в середине капса
            # (например, _L) макросом не является.
            if name.startswith("_"):
                continue

            # Встроенные константы вида BM_NORMAL, FA_LEFT пишутся капсом.
            if name.lower() in BUILTIN:
                continue

            line_no = code.count("\n", 0, match.start()) + 1
            problems.append(
                "%s:%d неизвестный макрос %s" % (rel, line_no, name)
            )

    print("Проверено файлов: %d" % checked)
    print("Объявлено функций: %d, макросов: %d" % (len(defined), len(macros)))

    if problems:
        print("\nНайдено проблем: %d\n" % len(problems))

        for problem in problems:
            print("  " + problem)

        return 1

    print("\nПроблем не найдено.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
