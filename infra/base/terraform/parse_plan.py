
import json

try:
    with open('tfplan.json', 'r') as f:
        data = json.load(f)
    
    creates = []
    for rc in data.get('resource_changes', []):
        if 'create' in rc.get('change', {}).get('actions', []):
            creates.append(rc['address'])
            
    print(f"COUNT:{len(creates)}")
    if len(creates) > 5:
        print("INVENTORY:")
        for c in creates:
            print(c)
            
except Exception as e:
    print(f"Error parsing json: {e}")
