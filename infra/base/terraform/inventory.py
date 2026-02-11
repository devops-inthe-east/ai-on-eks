import json
import os

try:
    if not os.path.exists('tfplan.json'):
        print("Error: tfplan.json not found.")
        exit(1)

    try:
        with open('tfplan.json', 'r', encoding='utf-8') as f:
            plan = json.load(f)
    except UnicodeDecodeError:
        # PowerShell redirection often creates UTF-16 files
        with open('tfplan.json', 'r', encoding='utf-16') as f:
            plan = json.load(f)
    
    creates = []
    # resource_changes contains all resources in the plan
    for rc in plan.get('resource_changes', []):
        # We only care about resources being created
        if 'create' in rc.get('change', {}).get('actions', []):
            creates.append(f"{rc['address']} ({rc['type']})")
    
    count = len(creates)
    output_lines = []
    output_lines.append(f"Total Resources to be Provisioned: {count}")
    
    if count > 5:
        output_lines.append("\n[INVENTORY - DETAILED LIST]")
        output_lines.append("===========================")
        for res in sorted(creates):
            output_lines.append(res)
    else:
        output_lines.append("\nAll resources (Count <= 5):")
        for res in sorted(creates):
            output_lines.append(res)
            
    with open('inventory_output.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(output_lines))
        
    print('\n'.join(output_lines))

except Exception as e:
    print(f"An error occurred: {e}")
