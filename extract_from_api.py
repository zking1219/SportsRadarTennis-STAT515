#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Nov 10 10:15:49 2019

@author: iaa211
"""

import requests
import json
import time

def query_api(api_key, endpoint, sleep_time, **kwargs):
    
    my_key = api_key
    endpoint = 'players/rankings'
    
    time.sleep(sleep_time)
    response = requests.get("https://api.sportradar.us/tennis-t2/en/{}.json".format(endpoint),
                                     params={'api_key':my_key,'format':'json'})
    response_json = response.json()
    
    return response_json