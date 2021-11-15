import re
from pathlib import Path
import json
import sys

### Command line argument parser
import argparse

default_group = 5

parser = argparse.ArgumentParser()
parser.add_argument("input_file_name", help=f"input file name")
parser.add_argument("-G", "--group", type=int, help=f"group number, default: {default_group}", nargs="?", default=default_group)
parser.add_argument("-y", "--assume-yes", help="automatic yes to prompts", action="store_true", default=False)
parser.add_argument("-v", "--verbose", help="print result to stdout", action="store_true", default=False)

if __name__ == "__main__":

  args = parser.parse_args()

  if not args.assume_yes:
    print("CLI args: {}".format(json.dumps(vars(args), indent=2)))
    c = input("Confirm? [y/n] ")
    if c != "y":
      sys.exit("No changes made.")

  G = args.group
  X = 10*G

  input_file_path = Path(__file__).absolute().parent.parent.joinpath(args.input_file_name)
  # print(input_file_path)

  output_file_path = input_file_path.parent.joinpath(f"G{G}_{input_file_path.name}")
  # print(output_file_path)

  file_content = open(input_file_path).read()

  # print(file_content)

  reg_exp = r"\-\-([GX]|[+]|[0-9])+\-\-"

  while ( m := re.search(reg_exp, file_content) ) is not None:
    matched_string = m.group()
    result = eval(matched_string.replace("--", ""))
    file_content = file_content.replace(matched_string, str(result))

  if args.verbose:
    print(file_content)

  open(output_file_path, "w").write(file_content)