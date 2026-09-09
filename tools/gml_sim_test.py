#!/usr/bin/env python3
"""Исполняемые проверки логики клиник VetSim (пакет №325).

GameMaker IDE в песочнице нет, поэтому ключевые функции клиники
исполняются на мини-интерпретаторе GML прямо из исходников проекта —
не из переписанной копии. Проверяется то, что пользователь просил
гарантировать:

  * четыре клиники с правильными потолками;
  * в клинике №1 нельзя открыть третий кабинет;
  * койки/палата/операционная есть только там, где предусмотрены;
  * слот найма упирается в 4 / 7 / 10 / 17;
  * ветки панели РАЗВИТИЕ собираются от данных клиники;
  * склад малый/средний/большой по данным клиники;
  * репутация, помещения, улучшения и картотека у каждой клиники свои,
    а деньги и баллы — общие.

Запуск:  python3 tools/gml_sim_test.py
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from gml_check import strip_code  # noqa: E402


def keep_strings(text):
    """Убирает комментарии, сохраняя содержимое строк."""
    return strip_code(text, keep_strings=True)


# ═══════════════════════════════════════════════════════════════
# 1. СБОР ИСХОДНИКОВ ФУНКЦИЙ
# ═══════════════════════════════════════════════════════════════

SOURCES = [
    "scripts/clinics_map_system/clinics_map_system.gml",
    "scripts/clinic_network_system/clinic_network_system.gml",
    "scripts/clinic_rooms_system/clinic_rooms_system.gml",
    "scripts/clinic_upgrade_system/clinic_upgrade_system.gml",
    "scripts/clinic_tree_panel/clinic_tree_panel.gml",
    "scripts/storage_visible_items/storage_visible_items.gml",
]

FUNC_START = re.compile(r"^function\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{", re.M)


def collect_assets():
    """Имена ассетов проекта: имя объекта/скрипта/спрайта в GML — это
    самостоятельное имя, а не переменная. Без этого списка
    `instance_exists(obj_UI_HUD)` падал как «неизвестное имя»."""
    assets = set()

    for folder in ("objects", "scripts", "sprites", "fonts", "shaders",
                   "tilesets", "rooms"):
        base = os.path.join(ROOT, folder)

        if not os.path.isdir(base):
            continue

        for name in os.listdir(base):
            if name.endswith(".yy"):
                assets.add(name[:-3])
            elif os.path.isdir(os.path.join(base, name)):
                assets.add(name)

    return assets


ASSETS = collect_assets()


def load_functions():
    """Возвращает {имя: (список параметров, тело)} для всех функций."""
    functions = {}

    for rel in SOURCES:
        path = os.path.join(ROOT, rel)

        with open(path, encoding="utf-8") as handle:
            raw = handle.read()

        # Комментарии убираем обязательно: фигурные скобки внутри них
        # сбивают поиск конца функции. Строки сохраняем — интерпретатор
        # проверяет логику на реальных ключах структур.
        code = keep_strings(raw)

        for match in FUNC_START.finditer(code):
            name = match.group(1)
            params = [p.strip() for p in match.group(2).split(",") if p.strip()]
            start = match.end() - 1
            body = extract_block(code, start)
            functions[name] = (params, body)

    return functions


def extract_block(code, brace_index):
    """Тело функции от открывающей { до парной }."""
    depth = 0

    for index in range(brace_index, len(code)):
        char = code[index]

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1

            if depth == 0:
                return code[brace_index + 1:index]

    raise ValueError("Незакрытая функция на позиции %d" % brace_index)


# ═══════════════════════════════════════════════════════════════
# 2. МИНИ-ИНТЕРПРЕТАТОР GML
#
# Покрывает ровно тот подмножество языка, которое реально встречается
# в проверяемых файлах. Всё остальное — явная ошибка, а не тихий пропуск.
# ═══════════════════════════════════════════════════════════════

MACROS = {
    "CLINIC_OPERATING_FREE_WHILE_TESTING": False,
    "CLINIC_CASE_GATE_ENABLED": True,
    "CLINIC_GATE_IGNORE_TESTING_UNLOCK": False,
    "CLINIC_BED_FIRST": 101,
    "CLINIC_BED_LAST": 108,
    "CLINIC_WARD_KEY": "ward",
    "TREE_HIRE_MAX_LEVEL": 14,
    "TREE_NODE_MIN_W": 520,
    "TREE_DOT_REFERENCE": 15,
    "UI_ROW_H": 44,
}


class GmlError(Exception):
    pass


# Слова, после которых скобка не является вызовом функции.
KEYWORDS = {
    "if", "while", "for", "switch", "with", "repeat", "return", "do",
    "function", "case", "and", "or", "not", "mod", "div", "xor", "else",
    "break", "continue", "exit", "var", "true", "false", "undefined",
    "noone", "enum",
}


class Interpreter:
    def __init__(self, functions, globals_):
        self.suppress = False
        # Глубина вложенности в литерал структуры. На глубине 1
        # двоеточие — разделитель «ключ : значение», поэтому тернарный
        # оператор там не разбирается; внутри (...) он снова разрешён.
        self.in_struct = 0
        self.no_ternary = False
        self.lazy = False
        self.functions = functions
        self.globals = globals_
        self.calls = []
        self.stack = []

    # ── публичный вход ──
    def call(self, name, *args):
        if name not in self.functions:
            raise GmlError("Функция %s() не найдена в исходниках" % name)

        params, body = self.functions[name]

        if len(params) != len(args):
            raise GmlError(
                "%s() ждёт %d аргументов, передано %d"
                % (name, len(params), len(args))
            )

        scope = dict(zip(params, args))
        scope["id"] = self

        # Аргументы передаются значениями, а не ссылками.
        args = [self.resolve(a, {}) if isinstance(a, tuple) else a for a in args]
        scope = dict(zip(params, args))
        scope["id"] = self

        self.calls.append(name)
        self.stack.append(name)

        try:
            return self.exec_block(body, scope)
        except GmlError:
            LAST_STACK[:] = list(self.stack)
            raise
        finally:
            self.stack.pop()

    # ── токенизация ──
    @staticmethod
    def tokenize(text):
        tokens = []
        index = 0
        length = len(text)

        while index < length:
            char = text[index]

            if char in " \t\r\n":
                index += 1
                continue

            # Двухсимвольные операторы проверяются ПЕРЕД одиночными:
            # «!», стоявший в одиночном наборе, резал «!=» на «!» и «=»,
            # и условие `_blocked != ''` разбиралось как префиксный «not».
            if text[index:index + 2] in (
                "==", "!=", ">=", "<=", "&&", "||",
                "+=", "-=", "*=", "/=", "++", "--"
            ):
                tokens.append(text[index:index + 2])
                index += 2
                continue

            if char in "{}();,[]:.?":
                tokens.append(char)
                index += 1
                continue

            if char in "=+-*/<>!":
                tokens.append(char)
                index += 1
                continue

            if char == '"' or char == "'":
                quote = char
                end = index + 1
                value = ""

                while end < length and text[end] != quote and text[end] != "\n":
                    value += text[end]
                    end += 1

                tokens.append(("str", value.strip()))

                # Перешагиваем закрывающую кавычку: без этого она
                # открывала следующую строку и съеживала ")" вместе с ней.
                index = end + 1 if end < length and text[end] == quote else end
                continue

            if char.isdigit():
                end = index

                while end < length and (text[end].isdigit() or text[end] == "."):
                    end += 1

                tokens.append(("num", float(text[index:end])))
                index = end
                continue

            if char.isalpha() or char == "_":
                end = index

                while end < length and (text[end].isalnum() or text[end] == "_"):
                    end += 1

                tokens.append(("ident", text[index:end]))
                index = end
                continue

            raise GmlError("Непонятный символ %r" % char)

        return tokens

    # ── исполнение блока ──
    def exec_block(self, body, scope):
        tokens = self.tokenize(body)
        position = 0
        result = None

        try:
            while position < len(tokens):
                statement, position = self.exec_statement(tokens, position, scope)

                if statement is not None:
                    result = statement
        except ReturnSignal as signal:
            return signal.value

        return result

    def exec_statement(self, tokens, position, scope):
        token = tokens[position]

        # Ключевые слова приходят как ("ident", "if") — сравнивать их
        # со строкой напрямую нельзя, иначе «if» уходил в разбор
        # выражения и ломал весь оператор.
        word = token[1] if isinstance(token, tuple) and token[0] == "ident" else None

        if token == "}":
            return None, position + 1

        if token == ";":
            return None, position + 1

        if token == "{":
            return self.exec_braced(tokens, position, scope)

        if word == "var":
            return self.exec_var(tokens, position, scope)

        if word == "if":
            return self.exec_if(tokens, position, scope)

        if word == "for":
            return self.exec_for(tokens, position, scope)

        if word == "switch":
            return self.exec_switch(tokens, position, scope)

        if word == "return":
            value, position = self.parse_expression(tokens, position + 1, scope)

            if position < len(tokens) and tokens[position] == ";":
                position += 1

            # Возвращаем ЗНАЧЕНИЕ: ссылка на локальную переменную после
            # выхода из функции была бы уже недействительна.
            raise ReturnSignal(self.resolve(value, scope))

        if word == "break":
            position += 1

            if position < len(tokens) and tokens[position] == ";":
                position += 1

            raise BreakSignal()

        if word == "continue":
            position += 1

            if position < len(tokens) and tokens[position] == ";":
                position += 1

            raise ContinueSignal()

        # Закрывающие разделители не начинают выражение: без этой
        # защиты разбор «доедал» лишнюю } и продолжал с пустого места.
        if token in (")", "]", "}", ",", ":", "?"):
            return None, position + 1

        # Присваивание или вызов.
        value, position = self.parse_expression(tokens, position, scope)

        # Постфиксные ++ и --: в шаге цикла for это единственный способ
        # сдвинуть счётчик, без него цикл не сходится.
        if position < len(tokens) and tokens[position] in ("++", "--"):
            step = 1 if tokens[position] == "++" else -1
            position += 1

            current = self.resolve(value, scope)
            self.assign(value, current + step, scope)

            if position < len(tokens) and tokens[position] == ";":
                position += 1

            return current, position

        if position < len(tokens) and tokens[position] in ("=", "+=", "-="):
            operator = tokens[position]
            target = value
            # Правая часть присваивания разбирается как полное выражение
            # с тернарным оператором: без этого `a = b ? c : d;`
            # останавливался на ":" и следующая инструкция начиналась
            # с двоеточия.
            raw, position = self.parse_expression(tokens, position + 1, scope)

            # В переменную кладётся ЗНАЧЕНИЕ, а не ссылка: иначе
            # global.clinics оказывался кортежем ("lit", [...]).
            value = self.resolve(raw, scope)

            if operator == "+=":
                value = self.resolve(target, scope) + value
            elif operator == "-=":
                value = self.resolve(target, scope) - value

            self.assign(target, value, scope)

        if position < len(tokens) and tokens[position] == ";":
            position += 1

        return value, position

    def exec_braced(self, tokens, position, scope):
        position += 1  # {

        while position < len(tokens) and tokens[position] != "}":
            _, position = self.exec_statement(tokens, position, scope)

        return None, position + 1

    def exec_var(self, tokens, position, scope):
        position += 1  # var

        # Цель может быть и полем: `var _state = ...` — обычный случай,
        # но GML допускает и `var global.x = ...`.
        name_token = tokens[position]
        name = name_token[1] if isinstance(name_token, tuple) else name_token
        position += 1

        target = name

        while position < len(tokens) and tokens[position] in (".", "["):
            if tokens[position] == ".":
                position += 1
                field_token = tokens[position]
                field = field_token[1] if isinstance(field_token, tuple) else field_token
                position += 1
                target = ("field", target, field)
            else:
                position += 1
                index, position = self.parse_expression(tokens, position, scope)
                target = ("index", target, index)

                assert tokens[position] == "]"
                position += 1

        value = None

        if position < len(tokens) and tokens[position] == "=":
            value, position = self.parse_expression(tokens, position + 1, scope)

        if isinstance(target, tuple):
            self.assign(("ref", target), self.resolve(value, scope), scope)
        else:
            scope[target] = self.resolve(value, scope)

        if position < len(tokens) and tokens[position] == ";":
            position += 1

        return value, position

    def exec_if(self, tokens, position, scope):
        """if (условие) ветка [else ветка]

        Не выполненная ветка ОБЯЗАНА пропускаться, а не исполняться:
        иначе клиники получали и стартовый набор, и миграцию сразу, и
        проверки показывали не то, что делает игра.
        """
        position += 1  # if
        raw_condition, position = self.parse_expression(tokens, position, scope)

        # Условие обязательно разыменовывается: ("lit", False) —
        # непустой кортеж, и без val() любая ветка считалась бы истиной.
        condition = bool(self.val(raw_condition, scope))

        then_start = position
        then_end = self.after_statement(tokens, then_start)

        else_start = None
        else_end = None

        _next = tokens[then_end] if then_end < len(tokens) else None
        _next_word = (
            _next[1] if isinstance(_next, tuple) and _next[0] == "ident" else None
        )

        if _next_word == "else":
            else_start = then_end + 1
            else_end = self.after_statement(tokens, else_start)

        if condition:
            result, _ = self.exec_statements_value(tokens, then_start, then_end, scope)
        elif else_start is not None:
            result, _ = self.exec_statements_value(tokens, else_start, else_end, scope)
        else:
            result = None

        return result, (else_end if else_end is not None else then_end)

    def exec_statements_value(self, tokens, start, end, scope):
        """Исполняет диапазон и возвращает последнее значение."""
        position = start
        result = None

        while position < end:
            statement, position = self.exec_statement(tokens, position, scope)

            if statement is not None:
                result = statement

        return result, position

    def exec_for(self, tokens, position, scope):
        """for (инициализация; условие; шаг) тело

        Границы трёх частей запоминаются позициями: условие
        перечитывается на каждой итерации.
        """
        position += 1  # for

        if tokens[position] != "(":
            raise GmlError("Ожидалась ( после for")

        position += 1

        init_start = position
        init_end = self.scan_to(tokens, init_start, ";")
        cond_start = init_end + 1
        cond_end = self.scan_to(tokens, cond_start, ";")
        step_start = cond_end + 1
        step_end = self.scan_paren(tokens, step_start)

        # Инициализация: одна инструкция без завершающей ";".
        if init_end > init_start:
            self.exec_statement(tokens, init_start, scope)

        body_start = step_end + 1
        body_end = self.after_statement(tokens, body_start)

        guard = 0

        while True:
            guard += 1

            if guard > 200000:
                raise GmlError("Цикл for не сходится")

            condition, _ = self.parse_expression(tokens, cond_start, scope)

            if not condition:
                break

            try:
                self.exec_statements(tokens, body_start, body_end, scope)
            except BreakSignal:
                break
            except ContinueSignal:
                pass

            if step_end > step_start:
                self.exec_statements(tokens, step_start, step_end, scope)

        return None, body_end

    @staticmethod
    def scan_to(tokens, position, needle):
        depth = 0

        while position < len(tokens):
            token = tokens[position]

            if isinstance(token, str):
                if token in "({[":
                    depth += 1
                elif token in ")}]":
                    depth -= 1
                elif token == needle and depth == 0:
                    return position

            position += 1

        return position

    def scan_paren(self, tokens, position):
        """Позиция ) , закрывающей блок for.

        Открывающей скобки в position уже нет — она съедена вызывающим
        кодом, поэтому ищем ту ")", которая возвращает глубину к нулю
        СПРАВА налево: первая встреченная ")" на нулевой глубине и есть
        закрывающая скобка for.
        """
        depth = 0

        while position < len(tokens):
            token = tokens[position]

            if isinstance(token, str):
                if token == "(":
                    depth += 1
                elif token == ")":
                    if depth == 0:
                        return position

                    depth -= 1

            position += 1

        raise GmlError("Незакрытая скобка в for")

    def exec_statements(self, tokens, start, end, scope):
        position = start

        while position < end:
            _, position = self.exec_statement(tokens, position, scope)

        return position

    def after_statement(self, tokens, position):
        token = tokens[position] if position < len(tokens) else None

        if token == "{":
            depth = 0

            while position < len(tokens):
                if tokens[position] == "{":
                    depth += 1
                elif tokens[position] == "}":
                    depth -= 1

                    if depth == 0:
                        return position + 1

                position += 1

            return position

        while position < len(tokens) and tokens[position] != ";":
            position += 1

        return position + 1

    def exec_block_from_tokens(self, tokens, scope):
        position = 0

        while position < len(tokens):
            _, position = self.exec_statement(tokens, position, scope)

    @staticmethod
    def skip_statement(tokens, position):
        depth = 0

        while position < len(tokens):
            token = tokens[position]

            if isinstance(token, str):
                if token in "({[":
                    depth += 1
                elif token in ")}]":
                    if depth == 0:
                        return position
                    depth -= 1
                elif token == ";" and depth == 0:
                    return position + 1

            position += 1

        return position

    def exec_switch(self, tokens, position, scope):
        position += 1  # switch
        subject, position = self.parse_expression(tokens, position, scope)

        assert tokens[position] == "{"
        position += 1

        result = None
        falling = False

        while position < len(tokens) and tokens[position] != "}":
            token = tokens[position]

            word = token[1] if isinstance(token, tuple) and token[0] == "ident" else None

            if word == "case":
                value, position = self.parse_expression(tokens, position + 1, scope)

                assert tokens[position] == ":"
                position += 1

                falling = self.loose_equal(subject, value)
                continue

            if word == "default":
                position += 1

                assert tokens[position] == ":"
                position += 1

                falling = True
                continue

            if word == "break":
                position += 1

                if position < len(tokens) and tokens[position] == ";":
                    position += 1

                falling = False
                continue

            statement, position = self.exec_statement(tokens, position, scope)

            if falling and statement is not None:
                result = statement

        return result, position + 1

    # ── выражения ──
    def val(self, node, scope):
        """Значение узла выражения: ссылку разыменовываем.

        Без этого `a < b` сравнивало КОРТЕЖ ("ref", "a") с числом и
        всегда давало False — циклы просто не выполнялись.
        """
        return self.resolve(node, scope)

    def parse_expression(self, tokens, position, scope):
        value, position = self.parse_or(tokens, position, scope)

        # Тернарный оператор: условие ? если_да : если_нет.
        #
        # Ветви разбираются по грамматике, а не «пропуском токенов до
        # точки с запятой»: поиск ";" уводил разбор на следующую
        # инструкцию, и она начиналась с закрывающей скобки.
        #
        # Внутри ветвей тернарный оператор отключён (флаг no_ternary).
        # Это стандартное разрешение неоднозначности «висячего
        # двоеточия»: в `a ? b ? c : d : e` первое ":" закрывает
        # внутренний тернарный оператор, второе — внешний.
        if (
            not self.no_ternary
            and self.in_struct == 0
            and position < len(tokens)
            and tokens[position] == "?"
        ):
            # Условие разыменовывается ДО отключения тернарного
            # оператора, а сам флаг живёт только на время разбора
            # ветвей и снимается сразу после: раньше он оставался
            # включённым во время вычисления ветви, и вызванные из неё
            # функции разбирались без тернарного оператора —
            # clinic_current_id() возвращал True вместо номера клиники.
            condition = self.val(value, scope)

            outer = self.no_ternary
            self.no_ternary = True

            try:
                # Ветви разбираются ЛЕНИВО: вызовы функций внутри них
                # исполняются только для выбранной ветки. Иначе
                # round(_slot_id) вычислялся бы и для _slot_id == "ward",
                # чего в игре не происходит.
                true_value, true_pos = self.parse_expression_lazy(
                    tokens, position + 1, scope
                )

                false_pos = true_pos
                false_value = None

                if true_pos < len(tokens) and tokens[true_pos] == ":":
                    false_value, false_pos = self.parse_expression_lazy(
                        tokens, true_pos + 1, scope
                    )
            finally:
                self.no_ternary = outer

            position = false_pos if false_value is not None else true_pos

            if condition:
                chosen = self.val(true_value(), scope)
            elif false_value is not None:
                chosen = self.val(false_value(), scope)
            else:
                chosen = UNDEFINED

            return ("lit", chosen), position

        return value, position

    @staticmethod
    def skip_braced(tokens, position):
        """Позиция сразу после парной } / ) / ]."""
        opener = tokens[position]
        closer = {"{": "}", "(": ")", "[": "]"}[opener]
        depth = 0

        while position < len(tokens):
            token = tokens[position]

            if isinstance(token, str):
                if token == opener:
                    depth += 1
                elif token == closer:
                    depth -= 1

                    if depth == 0:
                        return position + 1

            position += 1

        return position

    def parse_or(self, tokens, position, scope):
        value, position = self.parse_and(tokens, position, scope)

        while position < len(tokens) and tokens[position] == "||":
            other, position = self.parse_and(tokens, position + 1, scope)
            value = bool(self.val(value, scope)) or bool(self.val(other, scope))

        return value, position

    def parse_and(self, tokens, position, scope):
        value, position = self.parse_equality(tokens, position, scope)

        while position < len(tokens) and tokens[position] == "&&":
            other, position = self.parse_equality(tokens, position + 1, scope)
            value = bool(self.val(value, scope)) and bool(self.val(other, scope))

        return value, position

    def parse_equality(self, tokens, position, scope):
        value, position = self.parse_comparison(tokens, position, scope)

        while position < len(tokens) and tokens[position] in ("==", "!="):
            operator = tokens[position]
            other, position = self.parse_comparison(tokens, position + 1, scope)
            equal = self.loose_equal(
                self.val(value, scope), self.val(other, scope)
            )
            value = equal if operator == "==" else not equal

        return value, position

    def parse_comparison(self, tokens, position, scope):
        value, position = self.parse_additive(tokens, position, scope)

        while position < len(tokens) and tokens[position] in (">=", "<=", ">", "<"):
            operator = tokens[position]
            other, position = self.parse_additive(tokens, position + 1, scope)

            left = self.val(value, scope)
            right = self.val(other, scope)

            if operator == ">=":
                value = left >= right
            elif operator == "<=":
                value = left <= right
            elif operator == ">":
                value = left > right
            else:
                value = left < right

        return value, position

    def parse_additive(self, tokens, position, scope):
        value, position = self.parse_multiplicative(tokens, position, scope)

        while position < len(tokens) and tokens[position] in ("+", "-"):
            operator = tokens[position]
            other, position = self.parse_multiplicative(tokens, position + 1, scope)

            left = self.val(value, scope)
            right = self.val(other, scope)

            value = left + right if operator == "+" else left - right

        return value, position

    def parse_multiplicative(self, tokens, position, scope):
        value, position = self.parse_unary(tokens, position, scope)

        while position < len(tokens) and tokens[position] in ("*", "/", "mod"):
            operator = tokens[position]
            other, position = self.parse_unary(tokens, position + 1, scope)

            left = self.val(value, scope)
            right = self.val(other, scope)

            if operator == "*":
                value = left * right
            elif operator == "/":
                value = left / right if right != 0 else 0
            else:
                value = left % right

        return value, position

    def parse_unary(self, tokens, position, scope):
        token = tokens[position]

        if token == "!":
            value, position = self.parse_unary(tokens, position + 1, scope)
            return not self.val(value, scope), position

        if token == "-":
            value, position = self.parse_unary(tokens, position + 1, scope)
            return -self.val(value, scope), position

        if token == "(":
            value, position = self.parse_expression(tokens, position + 1, scope)

            if position >= len(tokens) or tokens[position] != ")":
                found = tokens[position] if position < len(tokens) else None

                raise GmlError(
                    "Ожидалась ) в %s, найдено %r (функция %s)"
                    % (
                        " ".join(
                            t[1] if isinstance(t, tuple) else t
                            for t in tokens[max(0, position - 6):position + 3]
                        ),
                        found,
                        self.stack[-1] if self.stack else "?",
                    )
                )

            return value, position + 1

        return self.parse_atom(tokens, position, scope)

    def parse_atom(self, tokens, position, scope):
        token = tokens[position]

        if isinstance(token, tuple) and token[0] == "num":
            return ("lit", token[1]), position + 1

        # Строковый литерал. Без этой ветки token[1] ниже возвращал ПЕРВЫЙ
        # СИМВОЛ строки: вызов variable_global_exists("clinics") уходил в
        # бесконечную рекурсию вместо передачи аргумента.
        if isinstance(token, tuple) and token[0] == "str":
            return ("lit", token[1]), position + 1

        if token == "{":
            value, position = self.parse_struct_literal(tokens, position, scope)
            return ("lit", value), position

        if token == "[":
            value, position = self.parse_array_literal(tokens, position, scope)
            return ("lit", value), position

        if isinstance(token, tuple) and token[0] == "ident":
            keyword = token[1]

            if keyword == "true":
                return ("lit", True), position + 1

            if keyword == "false":
                return ("lit", False), position + 1

            if keyword == "undefined":
                return ("lit", UNDEFINED), position + 1

            if keyword == "noone":
                return ("lit", None), position + 1

        name = token[1]
        position += 1

        # Вызов функции.
        if (
            name not in KEYWORDS
            and position < len(tokens)
            and tokens[position] == "("
        ):
            position += 1
            args = []

            while position < len(tokens) and tokens[position] != ")":
                # Литерал структуры как аргумент: { ok: false, ... }.
                # Без этой ветки parse_expression съедал только "{ ok",
                # и разбор съезжал до конца функции.
                if tokens[position] == "{":
                    value, position = self.parse_struct_literal(
                        tokens, position, scope
                    )
                else:
                    value, position = self.parse_expression(
                        tokens, position, scope
                    )

                args.append(value)

                if position < len(tokens) and tokens[position] == ",":
                    position += 1

            position += 1  # )

            if self.lazy:
                # Отложенный вызов: исполнится только если эта ветка
                # тернарного оператора окажется выбранной.
                call = (
                    lambda name=name, args=args, scope=scope:
                    self.call_function(name, args, scope)
                )

                return ("lit", call), position

            return ("lit", self.call_function(name, args, scope)), position

        # Доступ к полю: a.b.c
        target = name

        while position < len(tokens) and tokens[position] == ".":
            position += 1
            field_token = tokens[position]
            field = field_token[1] if isinstance(field_token, tuple) else field_token
            position += 1
            target = ("field", target, field)

        # Индекс: a[i]
        while position < len(tokens) and tokens[position] == "[":
            position += 1
            index, position = self.parse_expression(tokens, position, scope)

            assert tokens[position] == "]"
            position += 1

            target = ("index", target, index)

        return ("ref", target), position

    # Индекс массива хранится как узел выражения — разыменовывается
    # в unwrap, поэтому здесь ничего вычислять не нужно.

    def parse_struct_literal(self, tokens, position, scope):
        position += 1  # {
        result = {}

        # Внутри { ключ : значение } двоеточие принадлежит структуре.
        outer = self.in_struct
        self.in_struct = outer + 1

        while position < len(tokens) and tokens[position] != "}":
            key = tokens[position]

            if isinstance(key, tuple):
                key = key[1]

            position += 1

            assert tokens[position] == ":"

            # Значение разбирается на глубине наружного контекста:
            # на глубине 1 тернарный оператор отключён, и
            # `ключ : условие ? a : {}` терял ветку «иначе».
            depth = self.in_struct
            self.in_struct = depth - 1

            try:
                value, position = self.parse_expression(
                    tokens, position + 1, scope
                )
            finally:
                self.in_struct = depth

            # parse_expression возвращает ссылку или литерал, а в
            # структуру нужно положить ЗНАЧЕНИЕ — иначе вместо списка
            # клиник получался список кортежей ("lit", {...}).
            result[key] = self.resolve(value, scope)

            if position < len(tokens) and tokens[position] == ",":
                position += 1

        self.in_struct = outer

        return result, position + 1

    def parse_expression_lazy(self, tokens, position, scope):
        """Выражение, которое вычисляется по требованию.

        Нужно тернарному оператору: разбор обязан пройти обе ветви, а
        исполнить — только выбранную."""
        outer = self.lazy
        self.lazy = True

        try:
            node, end = self.parse_expression(tokens, position, scope)
        finally:
            self.lazy = outer

        return (lambda: node), end

    def parse_array_literal(self, tokens, position, scope):
        position += 1  # [
        result = []

        while position < len(tokens) and tokens[position] != "]":
            value, position = self.parse_expression(tokens, position, scope)
            result.append(self.resolve(value, scope))

            if position < len(tokens) and tokens[position] == ",":
                position += 1

        return result, position + 1

    # ── ссылки и присваивание ──
    def resolve(self, ref, scope):
        if not isinstance(ref, tuple):
            return ref

        if ref[0] == "lit":
            # Отложенный вызов из невычисленной ветки тернарного
            # оператора исполняется здесь — и только для выбранной ветки.
            if callable(ref[1]):
                return ref[1]()

            return ref[1]

        if ref[0] == "ref":
            return self.resolve_target(ref[1], scope)

        return ref

    def unwrap(self, target, scope):
        """Значение цели: ссылку разыменовываем, литерал отдаём как есть."""
        if isinstance(target, tuple) and target[0] == "ref":
            return self.resolve_target(target[1], scope)

        if isinstance(target, tuple) and target[0] == "lit":
            return target[1]

        return self.resolve_target(target, scope)

    def resolve_target(self, target, scope):
        if isinstance(target, tuple):
            kind = target[0]

            if kind == "field":
                base = self.unwrap(target[1], scope)

                if not isinstance(base, dict):
                    raise GmlError(
                        "Поле .%s у не-структуры (%r)" % (target[2], base)
                    )

                return base.get(target[2], UNDEFINED)

            if kind == "index":
                base = self.unwrap(target[1], scope)
                index = int(self.unwrap(target[2], scope))

                if index < 0 or index >= len(base):
                    raise GmlError("Выход за пределы массива: %d" % index)

                return base[index]

            raise GmlError("Неизвестная ссылка %r" % (target,))

        if target == "global":
            return self.globals

        if target in MACROS:
            return MACROS[target]

        if getattr(self, "suppress", False):
            return UNDEFINED

        if target in scope:
            return scope[target]

        if target in ASSETS:
            return ("sym", target)

        # В GML имя без префикса — это переменная экземпляра или
        # локальная, но НЕ global. Молчаливый поиск в globals скрыл бы
        # ошибку «забыли global.» в проверяемом коде.
        raise GmlError(
            "Неизвестное имя %r (область: %s)" % (target, sorted(scope.keys()))
        )

    def assign(self, ref, value, scope):
        if not isinstance(ref, tuple) or ref[0] != "ref":
            raise GmlError("Присваивание не в переменную: %r" % (ref,))

        target = ref[1]

        if isinstance(target, tuple):
            kind = target[0]

            if kind == "field":
                base = self.unwrap(target[1], scope)
                base[target[2]] = value
                return

            if kind == "index":
                base = self.unwrap(target[1], scope)
                base[int(self.unwrap(target[2], scope))] = value
                return

        if target == "global":
            raise GmlError("Нельзя присвоить global целиком")

        scope[target] = value

    def call_function(self, name, args, scope):
        if getattr(self, "suppress", False):
            return UNDEFINED

        if name in self.functions:
            params, body = self.functions[name]

            if len(params) != len(args):
                raise GmlError(
                    "%s() ждёт %d аргументов, передано %d"
                    % (name, len(params), len(args))
                )

            # Аргументы в функцию проекта тоже передаются ЗНАЧЕНИЯМИ:
            # без resolve() параметр оказывался узлом разбора
            # ("ref", "_default") и утекал наружу как результат.
            inner = dict(zip(params, self.resolve_args(args, scope)))
            inner["id"] = self
            self.stack.append(name)

            # Вызываемая функция всегда разбирается «с нуля»: флаги
            # тернарного оператора и литерала структуры относятся только
            # текущему выражению. Без этого функция, вызванная из ветви
            # тернарного оператора, разбиралась без "?" и возвращала
            # результат условия вместо значения.
            outer_ternary = self.no_ternary
            outer_struct = self.in_struct
            self.no_ternary = False
            self.in_struct = 0

            try:
                return self.exec_block(body, inner)
            except GmlError:
                LAST_STACK[:] = list(self.stack)
                raise
            finally:
                self.no_ternary = outer_ternary
                self.in_struct = outer_struct
                self.stack.pop()

        return self.call_builtin(name, self.resolve_args(args, scope))

    def resolve_args(self, args, scope):
        """Аргументы всегда разыменовываются до значений."""
        resolved = []

        for arg in args:
            try:
                resolved.append(self.resolve(arg, scope))
            except GmlError as error:
                raise GmlError(
                    "аргумент %r — %s (область: %s, стек: %s)"
                    % (arg, error, sorted(scope.keys()),
                       " -> ".join(self.stack))
                )

        return resolved

    @staticmethod
    def loose_equal(left, right):
        if left is UNDEFINED or right is UNDEFINED:
            return left is right

        if isinstance(left, bool) or isinstance(right, bool):
            return bool(left) == bool(right)

        if isinstance(left, (int, float)) and isinstance(right, (int, float)):
            return left == right

        return str(left) == str(right)

    # ── встроенные функции ──
    def call_builtin(self, name, args):
        handlers = {
            "string": lambda v: v if isinstance(v, str) else str(int(v)) if isinstance(v, float) and float(v).is_integer() else str(v),
            "round": lambda v: float(round(v)),
            "floor": lambda v: float(int(v // 1)),
            "ceil": lambda v: float(-int(-v // 1)),
            "clamp": lambda v, lo, hi: max(lo, min(hi, v)),
            "max": lambda *a: max(a),
            "min": lambda *a: min(a),
            "abs": lambda v: abs(v),
            "is_struct": lambda v: isinstance(v, dict),
            "is_array": lambda v: isinstance(v, list),
            "is_real": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
            "is_string": lambda v: isinstance(v, str),
            "is_undefined": lambda v: v is UNDEFINED,
            "array_length": lambda v: 0 if v is UNDEFINED else len(v),
            "array_push": lambda arr, *items: self._array_push(arr, items),
            "variable_global_exists": lambda k: k in self.globals,
            "variable_struct_exists": lambda s, k: isinstance(s, dict) and k in s,
            "variable_struct_get": lambda s, k: s.get(k, UNDEFINED),
            "variable_struct_set": lambda s, k, v: self._struct_set(s, k, v),
            "variable_struct_remove": lambda s, k: s.pop(k, None),
            "variable_struct_get_names": lambda s: list(s.keys()),
            "script_exists": lambda i: i != -1,
            "asset_get_index": lambda n: self._asset_index(n),
            "show_debug_message": lambda *a: None,
            "instance_number": lambda obj: 0,
            "instance_exists": lambda obj: False,
            "instance_find": lambda obj, i: None,
            # db_clients_init() живёт в db_clients_init.gml и просто
            # очищает 13 картотечных переменных — new_game() уже даёт
            # то же состояние, поэтому здесь заглушка.
            "db_clients_init": lambda: None,
            "is_instanceof": lambda inst, obj: (
                isinstance(inst, tuple) and inst and inst[0] == "sym"
                and (inst[1] == obj or inst[1].endswith(obj))
            ),
            # Копии структур из save_system: здесь заглушки, но точные —
            # логика клиник проверяется на настоящих копиях, а не на
            # общих ссылках.
            "save_copy_struct": lambda src: dict(src) if isinstance(src, dict) else {},
            "save_deep_copy": lambda v, d: self._deep_copy(v, d),
        }

        if name in handlers:
            try:
                return handlers[name](*args)
            except TypeError as error:
                raise GmlError(
                    "%s(%s): %s"
                    % (name, ", ".join(repr(a)[:40] for a in args), error)
                )

        raise GmlError("В мини-интерпретаторе нет встроенной %s()" % name)

    @staticmethod
    def _deep_copy(value, depth):
        if depth is UNDEFINED:
            depth = 12

        if isinstance(value, dict):
            if depth <= 0:
                return dict(value)

            return {k: Interpreter._deep_copy(v, depth - 1)
                    for k, v in value.items()}

        if isinstance(value, list):
            if depth <= 0:
                return list(value)

            return [Interpreter._deep_copy(v, depth - 1) for v in value]

        return value

    @staticmethod
    def _array_push(array, items):
        for item in items:
            array.append(item)

        return len(array)

    @staticmethod
    def _struct_set(struct, key, value):
        struct[key] = value
        return value

    def _asset_index(self, name):
        # Имена функций проекта «существуют», всё остальное — нет.
        if name in self.functions:
            return 1000 + len(name)

        return -1


class UNDEFINED_TYPE:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)

        return cls._instance

    def __repr__(self):
        return "undefined"

    def __bool__(self):
        return False


UNDEFINED = UNDEFINED_TYPE()


class BreakSignal(Exception):
    pass


class ReturnSignal(Exception):
    """return из вложенного блока: значение нужно поднять до вызывающего.

    Без этого `return` внутри if/for просто терялся, и функции вроде
    clinics_get всегда возвращали undefined.
    """

    def __init__(self, value):
        super().__init__("return")
        self.value = value


class ContinueSignal(Exception):
    pass


# ═══════════════════════════════════════════════════════════════
# 3. ПРОВЕРКИ
# ═══════════════════════════════════════════════════════════════

FAILURES = []
PASSES = []
LAST_STACK = []


def check(description, condition, detail=""):
    if condition:
        PASSES.append(description)
    else:
        FAILURES.append("%s%s" % (description, (" — " + detail) if detail else ""))


def new_game(active_clinic=1):
    """Свежая игра: общие переменные как после obj_Render → Create."""
    return {
        "clinic_money": 100000,
        "clinic_points": 300,
        "clinic_reputation": 35,
        "active_clinic": active_clinic,
        "inventory_main": {},
        "owner_db": {},
        "pet_db": {},
        "visit_db": {},
        "owner_list": [],
        "pet_list": [],
        "visit_list": [],
        "owner_uid": 0,
        "pet_uid": 0,
        "visit_uid": 0,
        "scheduled_visits": [],
        "scheduled_visit_uid": 0,
        "daily_random_visits": [],
        "daily_random_visit_uid": 0,
        "daily_random_spawned_today": 0,
    }


def main():
    functions = load_functions()

    print("Загружено функций из исходников: %d" % len(functions))

    for required in [
        "clinics_spec", "clinics_init", "clinics_get", "clinics_migrate_to_spec",
        "clinic_state_get", "clinic_state_reset", "clinic_current_id",
        "clinic_exam_room_limit", "clinic_bed_limit", "clinic_has_operating_room",
        "clinic_storage_size", "clinic_hire_max", "clinic_hire_max_level",
        "clinic_reputation_read", "clinic_apply_current", "clinic_adopt_globals",
        "clinic_room_is_open", "clinic_bed_is_open", "clinic_ward_is_open",
        "clinic_operating_is_open", "clinic_exam_room_is_open",
        "clinic_room_purchase", "clinic_room_purchase_blocked_reason",
        "clinic_upgrade_max_level_for", "clinic_get_hire_slots",
        "tree_sections", "storage_clinic_scale_step", "clinic_rooms_entries",
    ]:
        if required not in functions:
            print("НЕТ ФУНКЦИИ %s() — проверка невозможна" % required)
            return 1

    # ── 1. Четыре клиники и их потолки ──
    globals_ = new_game()
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")

    check("в сети ровно 4 клиники", len(globals_["clinics"]) == 4,
          "фактически %d" % len(globals_["clinics"]))

    expected = [
        (1, 2, 0, False, 0, 4),
        (2, 3, 2, False, 1, 7),
        (3, 4, 5, False, 1, 10),
        (4, 6, 8, True, 2, 17),
    ]

    for clinic_id, exam, beds, operating, storage, hire in expected:
        clinic = vm.call("clinics_get", float(clinic_id))

        check("клиника %d: кабинеты %d" % (clinic_id, exam),
              clinic["exam_max"] == exam, "фактически %s" % clinic["exam_max"])
        check("клиника %d: койки %d" % (clinic_id, beds),
              clinic["bed_max"] == beds, "фактически %s" % clinic["bed_max"])
        check("клиника %d: операционная %s" % (clinic_id, operating),
              bool(clinic["has_operating"]) is operating,
              "фактически %s" % clinic["has_operating"])
        check("клиника %d: склад %d" % (clinic_id, storage),
              clinic["storage_size"] == storage,
              "фактически %s" % clinic["storage_size"])
        check("клиника %d: штат %d" % (clinic_id, hire),
              clinic["hire_max"] == hire, "фактически %s" % clinic["hire_max"])

    # ── 2. Потолки через функции текущей клиники ──
    for clinic_id, exam, beds, operating, storage, hire in expected:
        globals_ = new_game(clinic_id)
        vm = Interpreter(functions, globals_)
        vm.call("clinics_init")

        check("clinic_exam_room_limit() клиники %d = %d" % (clinic_id, exam),
              vm.call("clinic_exam_room_limit") == exam)
        check("clinic_bed_limit() клиники %d = %d" % (clinic_id, beds),
              vm.call("clinic_bed_limit") == beds)
        check("clinic_storage_size() клиники %d = %d" % (clinic_id, storage),
              vm.call("clinic_storage_size") == storage)
        check("clinic_hire_max() клиники %d = %d" % (clinic_id, hire),
              vm.call("clinic_hire_max") == hire)
        check("clinic_hire_max_level() клиники %d = %d" % (clinic_id, hire - 1),
              vm.call("clinic_hire_max_level") == hire - 1)

    # ── 3. Панель развития: кабинет сверх потолка не появляется ──
    for clinic_id, exam, beds, operating, storage, hire in expected:
        globals_ = new_game(clinic_id)
        vm = Interpreter(functions, globals_)
        vm.call("clinics_init")
        vm.call("clinic_apply_current")

        sections = vm.call("tree_sections")
        titles = [section["title"] for section in sections]

        exam_section = None

        for section in sections:
            if section["title"] == "ПРИЁМ":
                exam_section = section

        exam_slots = (
            [node["key"] for node in exam_section["nodes"]]
            if exam_section else []
        )

        check("клиника %d: в ПРИЁМЕ нет кабинета сверх %d" % (clinic_id, exam),
              all(slot <= exam for slot in exam_slots),
              "узлы %s" % exam_slots)
        check("клиника %d: кабинет %d в панели есть" % (clinic_id, exam),
              exam in exam_slots, "узлы %s" % exam_slots)

        # Стационар
        ward_section = None

        for section in sections:
            if section["title"] == "СТАЦИОНАР":
                ward_section = section

        if beds == 0:
            check("клиника %d: ветки СТАЦИОНАР нет" % clinic_id,
                  "СТАЦИОНАР" not in titles)
        else:
            check("клиника %d: ветка СТАЦИОНАР есть" % clinic_id,
                  ward_section is not None)

            bed_slots = [
                node["key"] for node in ward_section["nodes"]
                if node["kind"] == "bed"
            ]

            check("клиника %d: коек в панели %d" % (clinic_id, beds - 2),
                  len(bed_slots) == beds - 2, "узлы %s" % bed_slots)
            check("клиника %d: койка %d есть" % (clinic_id, 100 + beds),
                  (100 + beds) in bed_slots, "узлы %s" % bed_slots)
            check("клиника %d: койки %d нет" % (clinic_id, 101 + beds),
                  (101 + beds) not in bed_slots, "узлы %s" % bed_slots)

        # Операционная
        if operating:
            check("клиника %d: ветка ОПЕРАЦИОННАЯ есть" % clinic_id,
                  "ОПЕРАЦИОННАЯ" in titles)
        else:
            check("клиника %d: ветки ОПЕРАЦИОННАЯ нет" % clinic_id,
                  "ОПЕРАЦИОННАЯ" not in titles)

        # Слот найма
        check("клиника %d: потолок слота найма %d" % (clinic_id, hire - 1),
              vm.call("clinic_upgrade_max_level_for", "hire_slot") == hire - 1)

    # ── 4. Покупка третьего кабинета в клинике №1 невозможна ──
    globals_ = new_game(1)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")

    reason = vm.call("clinic_room_purchase_blocked_reason", 3.0)
    check("клиника 1: третий кабинет отклонён", reason != "",
          "причина пустая")
    check("клиника 1: покупка третьего кабинета не проходит",
          vm.call("clinic_room_purchase", 3.0) is not True)
    check("клиника 1: третий кабинет закрыт",
          vm.call("clinic_room_is_open", 3.0) is False)

    reason = vm.call("clinic_room_purchase_blocked_reason", "ward")
    check("клиника 1: палата отклонена", reason != "", "причина пустая")
    check("клиника 1: койка 101 закрыта",
          vm.call("clinic_bed_is_open", 101.0) is False)
    check("клиника 1: операционная закрыта",
          vm.call("clinic_operating_is_open") is False)
    check("клиника 1: операционную купить нельзя",
          vm.call("clinic_room_purchase", "operating") is not True)

    # Второй кабинет в клинике №1 — можно.
    check("клиника 1: второй кабинет разрешён",
          vm.call("clinic_room_purchase_blocked_reason", 2.0) == "")
    check("клиника 1: второй кабинет покупается",
          vm.call("clinic_room_purchase", 2.0) is True)
    check("клиника 1: второй кабинет открыт",
          vm.call("clinic_exam_room_is_open", 2.0) is True)

    # ── 5. Койки клиники №3 (потолок 5) ──
    globals_ = new_game(3)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")

    check("клиника 3: койка 101 до палаты закрыта",
          vm.call("clinic_bed_is_open", 101.0) is False)
    check("клиника 3: палата покупается",
          vm.call("clinic_room_purchase", "ward") is True)
    check("клиника 3: после палаты койка 101 открыта",
          vm.call("clinic_bed_is_open", 101.0) is True)
    check("клиника 3: койка 102 открыта вместе с палатой",
          vm.call("clinic_bed_is_open", 102.0) is True)
    check("клиника 3: койка 105 можно купить",
          vm.call("clinic_room_purchase_blocked_reason", 105.0) == "")
    check("клиника 3: койка 106 сверх потолка отклонена",
          vm.call("clinic_room_purchase_blocked_reason", 106.0) != "")
    check("клиника 3: койка 106 закрыта",
          vm.call("clinic_bed_is_open", 106.0) is False)

    # ── 6. Операционная клиники №4 ──
    globals_ = new_game(4)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")

    check("клиника 4: операционная предусмотрена",
          vm.call("clinic_has_operating_room") is True)
    check("клиника 4: операционная не открыта бесплатно",
          vm.call("clinic_operating_is_open") is False)
    check("клиника 4: операционная покупается",
          vm.call("clinic_room_purchase", "operating") is True)
    check("клиника 4: операционная открыта",
          vm.call("clinic_operating_is_open") is True)
    check("клиника 4: койка 108 в пределах потолка",
          vm.call("clinic_room_purchase_blocked_reason", 108.0) != "Больше коек в этой клинике быть не может.")

    # ── 7. Склад по данным клиники, а не по кабинетам ──
    for clinic_id, exam, beds, operating, storage, hire in expected:
        globals_ = new_game(clinic_id)
        vm = Interpreter(functions, globals_)
        vm.call("clinics_init")
        vm.call("clinic_apply_current")

        check("клиника %d: размер склада %d" % (clinic_id, storage),
              vm.call("storage_clinic_scale_step") == storage)

    # ── 8. Слот найма не превышает потолок ──
    globals_ = new_game(1)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")
    globals_["clinic_points"] = 100000

    for _ in range(20):
        vm.call("clinic_upgrade_apply", "hire_slot")

    check("клиника 1: слотов найма не больше 4",
          vm.call("clinic_get_hire_slots") == 4,
          "фактически %s" % vm.call("clinic_get_hire_slots"))
    check("клиника 1: уровень слота найма упёрся в 3",
          vm.call("clinic_upgrade_level", "hire_slot") == 3)

    globals_ = new_game(4)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")
    globals_["clinic_points"] = 100000

    for _ in range(30):
        vm.call("clinic_upgrade_apply", "hire_slot")

    check("клиника 4: слотов найма не больше 17",
          vm.call("clinic_get_hire_slots") == 17,
          "фактически %s" % vm.call("clinic_get_hire_slots"))

    # ── 9. Раздельные репутация, помещения, улучшения и картотека ──
    globals_ = new_game(1)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")

    # Играем в клинике №1: репутация растёт, куплен кабинет, есть пациент.
    globals_["clinic_reputation"] = 48
    vm.call("clinic_room_purchase", 2.0)
    globals_["owner_db"]["owner_1"] = {"owner_id": "owner_1"}
    globals_["pet_db"]["pet_1"] = {"pet_id": "pet_1"}
    globals_["clinic_points"] = 500
    vm.call("clinic_upgrade_apply", "library")

    # Уезжаем в клинику №2: сворачиваем первую.
    vm.functions["clinic_room_owner"] = ([], "return 1;")
    vm.call("clinic_network_store_current")

    globals_["active_clinic"] = 2
    vm.functions["clinic_room_owner"] = ([], "return 2;")
    vm.call("clinic_network_restore", 2.0)

    check("клиника 2: своя репутация с нуля",
          globals_["clinic_reputation"] == 0,
          "фактически %s" % globals_["clinic_reputation"])
    check("клиника 2: чужой кабинет не открылся",
          vm.call("clinic_exam_room_is_open", 2.0) is False)
    check("клиника 2: своя пустая картотека",
          len(globals_["owner_db"]) == 0,
          "фактически %s" % list(globals_["owner_db"].keys()))
    check("клиника 2: свой уровень библиотеки",
          vm.call("clinic_upgrade_level", "library") == 0)
    check("деньги общие: кошелёк не изменился",
          globals_["clinic_money"] == 100000 - 1500,
          "фактически %s" % globals_["clinic_money"])

    # Возвращаемся в клинику №1 — её состояние должно вернуться.
    vm.functions["clinic_room_owner"] = ([], "return 1;")
    vm.call("clinic_network_restore", 1.0)

    check("клиника 1: репутация вернулась",
          globals_["clinic_reputation"] == 48,
          "фактически %s" % globals_["clinic_reputation"])
    check("клиника 1: купленный кабинет на месте",
          vm.call("clinic_exam_room_is_open", 2.0) is True)
    check("клиника 1: пациент вернулся в картотеку",
          "owner_1" in globals_["owner_db"])
    check("клиника 1: уровень библиотеки вернулся",
          vm.call("clinic_upgrade_level", "library") == 1)

    # ── 10. Продажа клиники чистит карман ──
    globals_ = new_game(1)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")
    vm.call("clinic_apply_current")
    globals_["clinic_reputation"] = 77
    vm.call("clinic_room_purchase", 2.0)
    vm.functions["clinic_room_owner"] = ([], "return 1;")
    vm.call("clinic_network_store_current")

    globals_["active_clinic"] = 2
    globals_["clinics"][1]["owned"] = True
    vm.functions["clinic_room_owner"] = ([], "return 2;")

    check("клинику №1 можно продать", vm.call("clinics_can_sell", globals_["clinics"][0])["ok"] is True)
    check("продажа клиники №1 прошла", vm.call("clinics_sell", 1.0) is True)

    pocket = globals_["clinic_state"]["clinic_1"]
    check("после продажи карман чист: персонал", len(pocket["staff"]) == 0)
    check("после продажи карман чист: склад", len(pocket["inventory"]) == 0)
    check("после продажи карман чист: помещения", pocket["rooms"] is UNDEFINED)
    check("после продажи карман чист: репутация", pocket["reputation"] is UNDEFINED)
    check("после продажи карман чист: картотека", pocket["db"] is UNDEFINED)

    # ── 11. Старое сохранение из шести клиник приводится к четырём ──
    globals_ = new_game(1)
    vm = Interpreter(functions, globals_)
    vm.call("clinics_init")

    # Имитируем загрузку старого сейва.
    old = vm.call("clinics_spec")
    old[3]["owned"] = True
    old[3]["reputation_start"] = 61
    old.append({"id": 5.0, "name": "Областная больница", "room_name": "",
                "owned": True, "price": 90000.0, "map_x": 0.81, "map_y": 0.6,
                "exam_rooms": 4.0, "beds": 8.0, "has_operating": True,
                "income_per_day": 6000.0, "unlock_note": "", "reputation": 12.0})
    old.append({"id": 6.0, "name": "Столичный госпиталь", "room_name": "",
                "owned": True, "price": 150000.0, "map_x": 0.92, "map_y": 0.24,
                "exam_rooms": 5.0, "beds": 10.0, "has_operating": True,
                "income_per_day": 8500.0, "unlock_note": "", "reputation": 4.0})
    old[1]["reputation"] = 22.0  # поле старой схемы
    globals_["clinics"] = old
    globals_["clinic_state"] = {"clinic_5": {"staff": []}, "clinic_6": {"staff": []}}

    vm.call("clinics_migrate_to_spec")

    check("миграция: клиник стало 4", len(globals_["clinics"]) == 4)
    check("миграция: покупка клиники 4 сохранилась",
          globals_["clinics"][3]["owned"] is True)
    check("миграция: репутация клиники 4 сохранилась",
          globals_["clinics"][3]["reputation_start"] == 61)
    check("миграция: репутация клиники 2 сохранилась",
          globals_["clinics"][1]["reputation_start"] == 22)
    check("миграция: потолок кабинетов клиники 1 восстановлен",
          globals_["clinics"][0]["exam_max"] == 2)
    check("миграция: карман клиники 5 удалён",
          "clinic_5" not in globals_["clinic_state"])
    check("миграция: карман клиники 6 удалён",
          "clinic_6" not in globals_["clinic_state"])

    # ── 12. Список помещений панели совпадает с потолками ──
    for clinic_id, exam, beds, operating, storage, hire in expected:
        globals_ = new_game(clinic_id)
        vm = Interpreter(functions, globals_)
        vm.call("clinics_init")
        vm.call("clinic_apply_current")

        entries = vm.call("clinic_rooms_entries")
        slots = [entry["slot"] for entry in entries]

        exam_slots = [s for s in slots if isinstance(s, float)]
        check("клиника %d: в списке помещений нет кабинета сверх %d"
              % (clinic_id, exam),
              all(s <= exam for s in exam_slots if s < 100),
              "слоты %s" % slots)
        check("клиника %d: операционная в списке %s" % (clinic_id, operating),
              ("operating" in slots) is operating, "слоты %s" % slots)

    # ── Итог ──
    print("\nПройдено проверок: %d" % len(PASSES))

    if FAILURES:
        print("ПРОВАЛЕНО: %d\n" % len(FAILURES))

        for failure in FAILURES:
            print("  × " + failure)

        return 1

    print("Все проверки пройдены.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except GmlError as error:
        print("\nОШИБКА ИНТЕРПРЕТАТОРА: %s" % error)
        print("Стек GML-вызовов: %s" % (" -> ".join(LAST_STACK) or "пуст"))
        sys.exit(2)
    except AssertionError as error:
        print("\nОШИБКА РАЗБОРА: %s" % error)
        sys.exit(2)
