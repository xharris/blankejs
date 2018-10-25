import json, csv

cards_path = "C:\\Users\\XHH\\Documents\\PROJECTS\\blankejs\\projects\\cardgame\\cards.csv"
json_path = "C:\\Users\\XHH\\Documents\\PROJECTS\\blankejs\\projects\\cardgame\\cards.json"
f_cards = open(cards_path, 'r')
line = f_cards.readline()
c = 0

out_table = []
trimmed_str = ""
while line and c < 24:
    if c > 0:
        line = f_cards.readline()
        trimmed_str += line
    c += 1

lines = csv.reader(trimmed_str.split('\n'))
for info in lines:
    if len(info) > 0:
        out_table.append({
            'card_type': info[0],
            'name': info[2],
            'attribute': info[1],
            'cost': info[3],
            'quick': (True if info == "TRUE" else False),
            'description': info[5]
       })

    line = f_cards.readline()
    c += 1

f_cards.close()

with open(json_path,'w') as out_file:
    json.dump(out_table, out_file)