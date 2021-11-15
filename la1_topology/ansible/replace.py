import re

in_file_name = "inventory.yml"

G = 4
X = 10*G

out_file_name = f"inventory_G{G}.yml"

file_content = open(in_file_name).read()

# print(file_content)

reg_exp = r"\-\-([GX]|[+]|[0-9])+\-\-"

while ( m := re.search(reg_exp, file_content) ) is not None:
  matched_string = m.group()
  result = eval(matched_string.replace("--", ""))
  file_content = file_content.replace(matched_string, str(result))

print(file_content)

open(out_file_name, "w").write(file_content)