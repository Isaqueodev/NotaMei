path = r'C:\Users\mathe\Documents\GitHub\NotaMei-clone\README.md'
with open(path, encoding='utf-8') as f:
    content = f.read()
start = content.find('## T01')
end = content.find('## Estado do projeto')
if start != -1 and end != -1:
    new_content = content[:start] + content[end:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('removed')
else:
    print('not found')
