#!/usr/bin/env python3
"""Assemble a sw/*.s program into the VHDL ROM constant of instruction_memory.vhd.

Supported: add sub and or mul (R), addi lw (I), sw (S), beq bne (B),
macdm rd, rs2, off(rs1) (custom-0, off in funct7) and nop.

Usage:
    asm2vhd.py prog.s                  print the ROM constant
    asm2vhd.py prog.s -o prog.vhd      write it to a file
"""

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROM_WORDS = 256
NOP_WORD = 0x00000013  # addi x0, x0, 0

# Formats: R, I, S and B are the standard RISC-V ones. L is an I-type whose
# operand is written off(rs1), M is macdm and N is nop.
# mnemonic: (format, opcode, funct3, funct7)
ISA = {
    "add":   ("R", 0b0110011, 0b000, 0b0000000),
    "sub":   ("R", 0b0110011, 0b000, 0b0100000),
    "and":   ("R", 0b0110011, 0b111, 0b0000000),
    "or":    ("R", 0b0110011, 0b110, 0b0000000),
    "mul":   ("R", 0b0110011, 0b000, 0b0000001),
    "addi":  ("I", 0b0010011, 0b000, None),
    "lw":    ("L", 0b0000011, 0b010, None),
    "sw":    ("S", 0b0100011, 0b010, None),
    "beq":   ("B", 0b1100011, 0b000, None),
    "bne":   ("B", 0b1100011, 0b001, None),
    "macdm": ("M", 0b0001011, 0b000, None),
    "nop":   ("N", None, None, None),
}

OPERAND_COUNT = {"R": 3, "I": 3, "L": 2, "S": 2, "B": 3, "M": 3, "N": 0}

LABEL_PATTERN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:")         # "loop:"
MEMORY_OPERAND_PATTERN = re.compile(r"^(-?\w+)\s*\(\s*(\w+)\s*\)$")   # "248(x0)"


class AsmError(Exception):
    pass


@dataclass
class Instruction:
    line_number: int
    mnemonic: str
    operands: list[str]   # still text, e.g. ["x2", "x4", "loop"]
    text: str             # the line without labels and comment
    comment: str
    labels: list[str]     # labels that point to this instruction


def parse_register(token: str) -> int:
    match = re.fullmatch(r"x(\d+)", token)
    if not match or int(match.group(1)) > 31:
        raise AsmError(f"invalid register '{token}'")
    return int(match.group(1))


def parse_immediate(token: str, bits: int, signed: bool = True) -> int:
    """Return the immediate as a `bits`-wide field (two's complement if negative)."""
    try:
        value = int(token, 0)
    except ValueError:
        raise AsmError(f"invalid immediate '{token}'")
    if signed:
        minimum, maximum = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    else:
        minimum, maximum = 0, (1 << bits) - 1
    if not minimum <= value <= maximum:
        raise AsmError(f"immediate {value} out of range [{minimum}, {maximum}]")
    return value & ((1 << bits) - 1)


def parse_memory_operand(token: str) -> tuple[str, int]:
    """Split "off(rs1)" into the offset text and the base register number."""
    match = MEMORY_OPERAND_PATTERN.match(token)
    if not match:
        raise AsmError(f"expected off(rs1), got '{token}'")
    return match.group(1), parse_register(match.group(2))


def first_pass(source: str) -> tuple[list[Instruction], dict[str, int]]:
    """Split each line into an Instruction and record the address of every label."""
    instructions: list[Instruction] = []
    label_addresses: dict[str, int] = {}
    pending_labels: list[str] = []   # labels waiting for the next instruction

    for line_number, line in enumerate(source.splitlines(), 1):
        code, _, comment = line.partition("#")
        code = code.strip()

        while (match := LABEL_PATTERN.match(code)):
            label = match.group(1)
            if label in label_addresses:
                raise AsmError(f"line {line_number}: label '{label}' redefined")
            label_addresses[label] = 4 * len(instructions)
            pending_labels.append(label)
            code = code[match.end():].strip()
        if not code:
            continue

        mnemonic, _, operand_text = code.partition(" ")
        mnemonic = mnemonic.lower()
        if mnemonic not in ISA:
            raise AsmError(f"line {line_number}: unknown instruction '{mnemonic}'")
        operands = [operand.strip() for operand in operand_text.split(",")] if operand_text.strip() else []
        expected_count = OPERAND_COUNT[ISA[mnemonic][0]]
        if len(operands) != expected_count:
            raise AsmError(f"line {line_number}: '{mnemonic}' takes {expected_count} operands, "
                           f"got {len(operands)}")

        instructions.append(Instruction(line_number, mnemonic, operands, code, comment.strip(), pending_labels))
        pending_labels = []

    if pending_labels:
        raise AsmError(f"label(s) {', '.join(pending_labels)} at end of file point to no instruction")
    if len(instructions) > ROM_WORDS:
        raise AsmError(f"program has {len(instructions)} instructions, ROM holds {ROM_WORDS}")
    return instructions, label_addresses


def encode(instruction: Instruction, address: int, label_addresses: dict[str, int]) -> int:
    """Second pass: build the 32-bit word of one instruction."""
    instr_format, opcode, funct3, funct7 = ISA[instruction.mnemonic]
    operands = instruction.operands

    if instr_format == "N":
        return NOP_WORD

    # funct7 | rs2 | rs1 | funct3 | rd | opcode
    if instr_format == "R":
        rd, rs1, rs2 = parse_register(operands[0]), parse_register(operands[1]), parse_register(operands[2])
        return funct7 << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode

    # imm[11:0] | rs1 | funct3 | rd | opcode
    if instr_format == "I":
        rd, rs1 = parse_register(operands[0]), parse_register(operands[1])
        immediate = parse_immediate(operands[2], 12)
        return immediate << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode

    if instr_format == "L":
        rd = parse_register(operands[0])
        offset, rs1 = parse_memory_operand(operands[1])
        immediate = parse_immediate(offset, 12)
        return immediate << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode

    # imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
    if instr_format == "S":
        rs2 = parse_register(operands[0])
        offset, rs1 = parse_memory_operand(operands[1])
        immediate = parse_immediate(offset, 12)
        return ((immediate >> 5) << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12
                | (immediate & 0x1F) << 7 | opcode)

    # imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode  (imm[0] is always 0)
    if instr_format == "B":
        rs1, rs2, target = parse_register(operands[0]), parse_register(operands[1]), operands[2]
        if target in label_addresses:
            offset = label_addresses[target] - address
        else:
            try:
                offset = int(target, 0)
            except ValueError:
                raise AsmError(f"undefined label '{target}'")
        if offset % 2:
            raise AsmError(f"branch offset {offset} is not even")
        immediate = parse_immediate(str(offset), 13)
        return ((immediate >> 12 & 1) << 31 | (immediate >> 5 & 0x3F) << 25 | rs2 << 20 | rs1 << 15
                | funct3 << 12 | (immediate >> 1 & 0xF) << 8 | (immediate >> 11 & 1) << 7 | opcode)

    # R-type layout with the word offset in funct7: off | rs2 | rs1 | funct3 | rd | opcode
    if instr_format == "M":
        rd, rs2 = parse_register(operands[0]), parse_register(operands[1])
        offset, rs1 = parse_memory_operand(operands[2])
        word_offset = parse_immediate(offset, 7, signed=False)
        return word_offset << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode

    raise AssertionError(instr_format)


def assemble(source: str) -> tuple[list[Instruction], list[int]]:
    instructions, label_addresses = first_pass(source)
    words = []
    for index, instruction in enumerate(instructions):
        try:
            words.append(encode(instruction, 4 * index, label_addresses))
        except AsmError as error:
            raise AsmError(f"line {instruction.line_number}: {error}") from None
    return instructions, words


def to_vhdl(instructions: list[Instruction], words: list[int]) -> str:
    # Column widths, so that "=>" and the comments line up
    index_width = len(str(len(words) - 1))
    text_width = max((len(instruction.text) for instruction in instructions), default=0)

    lines = ["constant ROM : memory_t := ("]
    for index, (instruction, word) in enumerate(zip(instructions, words)):
        for label in instruction.labels:
            lines.append(f"    -- {label}:")
        comment = f"-- {instruction.text.ljust(text_width)}  {instruction.comment}".rstrip()
        lines.append(f'    {index:<{index_width}} => x"{word:08X}", {comment}')
    lines.append(f'    others => x"{NOP_WORD:08X}" -- nop')
    lines.append(");")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Assemble a .s program into the instruction_memory ROM.")
    parser.add_argument("source", type=Path)
    parser.add_argument("-o", "--output", type=Path, help="write the ROM constant to this file")
    args = parser.parse_args()

    try:
        instructions, words = assemble(args.source.read_text())
        rom = to_vhdl(instructions, words)
        if args.output:
            args.output.write_text(rom)
        else:
            sys.stdout.write(rom)
    except AsmError as error:
        sys.exit(f"{args.source}: {error}")


if __name__ == "__main__":
    main()
