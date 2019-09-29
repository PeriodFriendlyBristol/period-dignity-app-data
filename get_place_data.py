def get_place_ids(query):
    import json
    import requests
    api_key = 'AIzaSyBRg0Viw0CUaZPVTmx-Yg8SRRAHBnjE0xg'
    url = 'https://maps.googleapis.com/maps/api/place/'\
            f'findplacefromtext/json?key={api_key}'\
            f'&inputtype=textquery&region=uk&input={query}'
    json_data = json.loads(requests.get(url).text)
    candidates = json_data['candidates']
    return [candidate['place_id'] for candidate in candidates]
    
def get_place_data(query):
    import json
    import requests
    import re

    place_ids = get_place_ids(query)
    if not place_ids:
        return None
    place_id = place_ids[0]

    api_key = 'AIzaSyBRg0Viw0CUaZPVTmx-Yg8SRRAHBnjE0xg'
    url = 'https://maps.googleapis.com/maps/api/place/'\
            f'details/json?key={api_key}'\
            f'&place_id={place_id}'

    json_data = json.loads(requests.get(url).text)
    result = json_data['result']

    data = {
        'name': None,
        'premise': None,
        'street_name': None, 
        'street_number': None, 
        'city': None, 
        'postcode': None,
        'phone': None,
        'lat': None,
        'lng': None
        }

    try:
        data['name'] = result['name']
    except KeyError:
        data['name'] = ''

    for component in result['address_components']:
        if 'route' in component['types']:
            data['street_name'] = component['long_name']
        elif 'street_number' in component['types']:
            data['street_number'] = component['long_name']
        elif 'premise' in component['types']:
            data['premise'] = component['long_name']
        elif 'postal_town' in component['types']:
            data['city'] = component['long_name']
        elif 'postal_code' in component['types']:
            data['postcode'] = component['long_name']

    try:
        data['phone'] = result['formatted_phone_number']
    except KeyError:
        data['phone'] = ''

    data['lat'] = result['geometry']['location']['lat']
    data['lng'] = result['geometry']['location']['lng']

    days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
    for day in days:
        data[day + '_open'] = None
        data[day + '_close'] = None
    try:
        for period in result['opening_hours']['periods']:
            for x in ['open', 'close']:
                try:
                    day_idx = period[x]['day']
                    day = dict(list(enumerate(days)))[day_idx]
                    data[day + '_' + x] = re.sub(r'([0-9]{2})([0-9]{2})', 
                        r'\1:\2', period[x]['time'])
                except KeyError:
                    pass
        data['opening_hours'] = True
    except KeyError:
        data['opening_hours'] = False

    return data

def populate_sheet(file_name):
    import pandas as pd
    from tqdm import trange

    df = pd.read_csv(file_name + '.csv')
    pbar = trange(df.shape[0])
    pbar.set_description(f'Fetching data from {file_name}')
   
    def clean(x):
        import numpy as np
        if not isinstance(x, str) and np.isnan(x):
            return ''
        else:
            return str(x) + ' '

    for row in pbar:
        query = clean(df.loc[row, 'NAME']) + \
                clean(df.loc[row, 'ADDRESS1']) + \
                clean(df.loc[row, 'ADDRESS2']) + \
                clean(df.loc[row, 'ADDRESS3']) + \
                clean(df.loc[row, 'POSTCODE']) + \
                clean(df.loc[row, 'CITY'])
        data = get_place_data(query)

        if data:
            if data['name']:
                df.loc[row, 'NAME'] = data['name']
            if data['premise']:
                address1 = data['premise']
                if data['street_name']:
                    if data['street_number']:
                        address2 = data['street_number'] + ' ' + \
                            data['street_name']
                    else:
                        address2 = data['street_name']
            else:
                if data['street_name']:
                    if data['street_number']:
                        address1 = data['street_number'] + ' ' + \
                            data['street_name']
                    else:
                        address1 = data['street_name']
                    address2 = None
            
            if address1:
                df.loc[row, 'ADDRESS1'] = address1
                df.loc[row, 'ADDRESS2'] = address2
                df.loc[row, 'ADDRESS3'] = None
            if data['city']:
                df.loc[row, 'CITY'] = data['city']
            if data['postcode']:
                df.loc[row, 'POSTCODE'] = data['postcode']
            if data['phone']:
                df.loc[row, 'PHONE_PRIMARY'] = data['phone']

            df.loc[row, 'LAT'] = data['lat']
            df.loc[row, 'LNG'] = data['lng']

            df.loc[row, 'OPENING_HOURS'] = data['opening_hours']

            for day in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']:
                df.loc[row, day.upper() + '_OPEN'] = data[day + '_open']
                df.loc[row, day.upper() + '_CLOSE'] = data[day + '_close']

    df.to_csv(file_name + '_modified.csv', header = True, index = False)

if __name__ == '__main__':
    populate_sheet('community_centres')
    populate_sheet('gps')
    populate_sheet('foodbanks')
