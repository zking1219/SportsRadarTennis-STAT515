###################################
# Simple Program to make a call to
# SportsRadar's Tennis API v2
###################################

import requests
import json
import numpy
import pandas as pd
import time

f = open('data/my_api_key.json','r')
my_key = json.load(f)['api_key']
f.close()

try:
    response_rankings = requests.get("https://api.sportradar.us/tennis-t2/en/players/rankings.json",
                                     params={'api_key':my_key,'format':'json'})
    rankings_json = response_rankings.json()
except json.JSONDecodeError:
    time.sleep(2)
    response_rankings = requests.get("https://api.sportradar.us/tennis-t2/en/players/rankings.json",
                                     params={'api_key':my_key,'format':'json'})
    rankings_json = response_rankings.json()

ranks = rankings_json['rankings']

# ATP rankings
djoker = ranks[1]['player_rankings'][0]
djoker_id = ranks[1]['player_rankings'][0]['player']['id']

# Lets see if we can get up to 100 djoker matches
djokers_matches = []
for i in numpy.arange(0,100,10):
    time.sleep(1.1)
    matches_response = requests.get("https://api.sportradar.us/tennis-t2/en/players/{}/results.json".format(djoker_id),
                                    params={'api_key':my_key,'format':'json','start':i})
    match_list = matches_response.json()['results']
    djokers_matches = djokers_matches + match_list
    
# Filter down to 2019 only
# get the date by djokers_matches[i]['sport_event_status']['match_ended']
# and picking off the year
djoker_2019 = []
for match in djokers_matches:
    try:
        myear = int(match['sport_event_status']['match_ended'].split('-')[0])
    except:
        myear = int(match['sport_event']['scheduled'].split('-')[0])
    if myear == 2019:
        djoker_2019.append(match)

match_dict = {}
for match in djoker_2019:
    match_id = match['sport_event']['id']
    print("Querying SportsRadar for {}".format(match_id))
    time.sleep(1.1)
    match_response = requests.get("https://api.sportradar.us/tennis-t2/en/matches/{}/summary.json".format(match_id),
                                  params={'api_key':my_key,'format':'json'})
    match_dict[match_id] = match_response.json()


# Extract stats from the parallel coordinates chart at 
# https://tennisvisuals.com/
# Need (for both players):
# 1. double_faults
# 2. aces
# 3. points won
# 4. first_serve_points_won
# 5. second_serve_points_won
# 6. total_breakpoints
# 7. breakpoints_won
# 8. first_serve_successful
# 9. second_serve_successful
# 10. service_points_won
# 11. receiver_points_won
# Need:
# 1. winnner_id (check if its djoker)
# 2. tournament/type (check if singles)
# 3. tournament id (extract surface)
#
# to derive
# a. total points served (first_serve_successful + second_serve_successful + double_faults)
# 1. double_fault percentage (double_faults / total points served)
# 2. ace percentage (double_faults / total points served)
# 3. total points (total points served + total points served[opponent])
# 4. first serve points won % (first_serve_points_won/first_serve_successful)
# 5. second serve points won % (second_serve_points_won/second_serve_successful)
# 6. first serve % (first_serve_successful / total points served)
# 7. total points won (points_won)
# 8. receiver points won (receiver_points_won)
djoker_id = 'sr:competitor:14882'

aces = []
double_faults = []
points_won = []
first_serve_points_won = []
second_serve_points_won = []
total_breakpoints = []
breakpoints_won = []
first_serve_successful = []
second_serve_successful = []
service_points_won = []
receiver_points_won = []
is_winner = []
match_type = []
tournament_id = []
opp_aces = []
opp_double_faults = []
opp_points_won = []
opp_first_serve_points_won = []
opp_second_serve_points_won = []
opp_total_breakpoints = []
opp_breakpoints_won = []
opp_first_serve_successful = []
opp_second_serve_successful = []
opp_service_points_won = []
opp_receiver_points_won = []

for match in djoker_2019:
    id1 = match['sport_event']['id']
    print ("Processing {}".format(id1))
    match1 = match_dict[id1]
    # make sure the match was actually contested (not a walkover)
    if match1['sport_event_status']['match_status'] not in ['ended','retired']:
        print ("Match ID: {} not processed; it was a {}".format(id1,
               match1['sport_event_status']['match_status']))
        continue
    # make sure djokers and the opponenets stats are assigned correctly
    # verify that match1['statistics']['teams'][0]['id'] == djoker_id
    if match1['statistics']['teams'][0]['id'] == djoker_id:
        djoker_stats = match1['statistics']['teams'][0]
        opponent_stats = match1['statistics']['teams'][1]
    elif match1['statistics']['teams'][1]['id'] == djoker_id:
        djoker_stats = match1['statistics']['teams'][1]
        opponent_stats = match1['statistics']['teams'][0]
    else:
        print("Problem with match {}".format(id1))
        continue
        
    aces.append(djoker_stats['statistics']['aces'])
    double_faults.append(djoker_stats['statistics']['double_faults'])
    points_won.append(djoker_stats['statistics']['points_won'])
    first_serve_points_won.append(djoker_stats['statistics']['first_serve_points_won'])
    second_serve_points_won.append(djoker_stats['statistics']['second_serve_points_won'])
    total_breakpoints.append(djoker_stats['statistics']['total_breakpoints'])
    breakpoints_won.append(djoker_stats['statistics']['breakpoints_won'])
    first_serve_successful.append(djoker_stats['statistics']['first_serve_successful'])
    second_serve_successful.append(djoker_stats['statistics']['second_serve_successful'])
    service_points_won.append(djoker_stats['statistics']['service_points_won'])
    receiver_points_won.append(djoker_stats['statistics']['receiver_points_won'])
    
    is_winner.append(match1['sport_event_status']['winner_id'] == djoker_id)
    match_type.append(match1['sport_event']['tournament']['type'])
    tournament_id.append(match1['sport_event']['tournament']['id'])
    
    opp_aces.append(opponent_stats['statistics']['aces'])
    opp_double_faults.append(opponent_stats['statistics']['double_faults'])
    opp_points_won.append(opponent_stats['statistics']['points_won'])
    opp_first_serve_points_won.append(opponent_stats['statistics']['first_serve_points_won'])
    opp_second_serve_points_won.append(opponent_stats['statistics']['second_serve_points_won'])
    opp_total_breakpoints.append(opponent_stats['statistics']['total_breakpoints'])
    opp_breakpoints_won.append(opponent_stats['statistics']['breakpoints_won'])
    opp_first_serve_successful.append(opponent_stats['statistics']['first_serve_successful'])
    opp_second_serve_successful.append(opponent_stats['statistics']['second_serve_successful'])
    opp_service_points_won.append(opponent_stats['statistics']['service_points_won'])
    opp_receiver_points_won.append(opponent_stats['statistics']['receiver_points_won'])

djoker_df = pd.DataFrame({'aces' : aces, 
                          'double_faults' : double_faults,
                          'points_won' : points_won, 
                          'first_serve_points_won' : first_serve_points_won,
                          'second_serve_points_won' : second_serve_points_won,
                          'total_breakpoints' : total_breakpoints,
                          'breakpoins_won' : breakpoints_won,
                          'first_serve_successful' : first_serve_successful,
                          'second_serve_successful' : second_serve_successful,
                          'service_points_won' : service_points_won,
                          'receiver_points_won' : receiver_points_won,
                          'is_winner' : is_winner,
                          'match_type' : match_type,
                          'tournament_id' : tournament_id,
                          'opp_aces' : opp_aces, 
                          'opp_double_faults' : opp_double_faults,
                          'opp_points_won' : opp_points_won, 
                          'opp_first_serve_points_won' : opp_first_serve_points_won,
                          'opp_second_serve_points_won' : opp_second_serve_points_won,
                          'opp_total_breakpoints' : opp_total_breakpoints,
                          'opp_breakpoins_won' : opp_breakpoints_won,
                          'opp_first_serve_successful' : opp_first_serve_successful,
                          'opp_second_serve_successful' : opp_second_serve_successful,
                          'opp_service_points_won' : opp_service_points_won,
                          'opp_receiver_points_won' : opp_receiver_points_won})

# to derive
# a. total points served (first_serve_successful + second_serve_successful + double_faults)
# 1. double_fault percentage (double_faults / total points served)
# 2. ace percentage (double_faults / total points served)
# 3. total points (total points served + total points served[opponent])
# 4. first serve points won % (first_serve_points_won/first_serve_successful)
# 5. second serve points won % (second_serve_points_won/second_serve_successful)
# 6. first serve % (first_serve_successful / total points served)
# 7. total points won (points_won)
# 8. receiver points won (receiver_points_won)

djoker_df['total_points_served'] = djoker_df.apply(lambda x: x['first_serve_successful'] + 
                                                     x['second_serve_successful'] +
                                                     x['double_faults'], axis=1)
djoker_df['opp_total_points_served'] = djoker_df.apply(lambda x: x['opp_first_serve_successful'] + 
                                                     x['opp_second_serve_successful'] +
                                                     x['opp_double_faults'], axis=1)
djoker_df['double_fault_percentage'] = djoker_df.apply(lambda x: x['double_faults']/x['total_points_served'], axis=1)
djoker_df['ace_percentage'] = djoker_df.apply(lambda x: x['aces']/x['total_points_served'], axis=1)
djoker_df['total_points'] = djoker_df.apply(lambda x: x['total_points_served'] + x['opp_total_points_served'], axis=1)
djoker_df['first_serve_points_won_pct'] = djoker_df.apply(lambda x: x['first_serve_points_won']/x['first_serve_successful'], axis=1)
djoker_df['second_serve_points_won_pct'] = djoker_df.apply(lambda x: x['second_serve_points_won']/x['second_serve_successful'], axis=1)
djoker_df['first_serve_pct'] = djoker_df.apply(lambda x: x['first_serve_successful']/x['total_points_served'], axis=1)

# Extract unique tournament_ids; then query the SportsRadar API to get the
# tournament surface
tourny_ids = djoker_df['tournament_id'].unique()
tourny_dict = {}
for tid in tourny_ids:
    time.sleep(1.1)
    print("Processing tournament {}".format(tid))
    tourny_response = requests.get("https://api.sportradar.us/tennis-t2/en/tournaments/{}/info.json".format(tid),
                                   params={'api_key':my_key,'format':'json'})
    tourny_dict[tid] = tourny_response.json()

djoker_df['surface'] = djoker_df.apply(lambda x: tourny_dict[x['tournament_id']]['info']['surface'], axis=1)
djoker_df.to_csv("NovakDjokovic2019matchStats.csv",index=False)    
    