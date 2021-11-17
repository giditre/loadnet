#!/usr/bin/python3

import re
from pathlib import Path
import json
import sys
import argparse

# CLI arguments default values
default_group = 4

# CLI argument parser
parser = argparse.ArgumentParser(description="Replace operations like --G-- or --X+1-- with their results in text files.")
parser.add_argument("input_file_name_list", type=str, nargs="+", metavar="file_name",
  help=f"input file name(s)")
parser.add_argument("-G", "--group", type=int, default=default_group, metavar="G",
  help=f"group number, default: {default_group}")
parser.add_argument("-y", "--assume-yes", action="store_true", default=False,
  help="automatically answer yes to prompts")
parser.add_argument("--show", action="store_true", default=False,
  help="show result of replacement on stdout")

if __name__ == "__main__":

  # parse CLI arguments
  args = parser.parse_args()

  # unless overridden, ask user for confirmation
  if not args.assume_yes:
    print("CLI args: {}".format(json.dumps(vars(args), indent=2)))
    c = input("Confirm? [y/n] ")
    if c != "y":
      sys.exit("No changes made.")

  # process CLI arguments and compute derived parameters
  G = args.group
  X = 10*G
  input_file_path_list = [ Path(__file__).absolute().parent.parent.joinpath(in_f)
    for in_f in args.input_file_name_list ]
  # print(input_file_path_list)

  # make sure all paths point to existing files in the system, otherwise exit
  if not all( p.is_file() for p in input_file_path_list ):
    sys.exit("ERROR: non-existing input file(s).")

  # loop over provided input files (now converted to paths)
  for input_file_path in input_file_path_list:

    # print(input_file_path)

    # define the output file name based on the input file name
    # e.g., if G=4 and input=foo.conf then output=G4_foo.conf
    output_file_path = input_file_path.parent.joinpath(f"G{G}_{input_file_path.name}")
    # print(output_file_path)

    # read the whole content of the input file as a single string into a variable
    file_content = open(input_file_path).read()
    # print(file_content)

    # define regular expression that matches strings like "--G--" or "--X+1--"
    reg_exp = r"\-\-[GX+0-9]+\-\-"
    # \- : the hyphen "-" has a meaning in regexps so it must be escaped with a backslash "\"
    # [GX+0-9] : match one of the characters in the set (G or X or + or a number in range 0-9)
    # + : one or more instances of the preceding character

    # look for instances of the string to be replaced and keep looping until there are more
    while ( m := re.search(reg_exp, file_content) ) is not None:
      # retrieve the matched string
      matched_string = m.group()
      # remove the leading and trailing hyphens leaving only the expression to be evaluated
      operation = matched_string.replace("--", "")
      # treat the string as a piece of code and compute the result of the operation
      result = eval(operation)
      # replace the matched string with the result of the operation throughout the text
      file_content = file_content.replace(matched_string, str(result))

    # if requested, print the content of the processed file on stdout
    if args.show:
      print(file_content)

    # create the output file
    open(output_file_path, "w").write(file_content)
