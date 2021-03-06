#!/usr/bin/python3

import re

in_file_name = "inventory.yml"

G = 4
X = 10*G

out_file_name = f"G{G}_inventory.yml"

file_content = open(in_file_name).read()

# print(file_content)

reg_exp = r"\-\-[GX+0-9]+\-\-"

while ( m := re.search(reg_exp, file_content) ) is not None:
  matched_string = m.group()
  operation = matched_string.replace("--", "")
  result = eval(operation)
  file_content = file_content.replace(matched_string, str(result))

print(file_content)

open(out_file_name, "w").write(file_content)