# SportsRadarTennis-STAT515
Python and R code for extracting data from SportsRadar's Tennis API and creating visualizations, respectively.

## Usage
Right now, this repo is capable of is retrieving statistics on ATP Men's Tennis 
World Number 1, Novak Djokovic's 2019 matches that correspond to the values used
in this parallel coordinates chart: ﻿https://tennisvisuals.com/ 

The output is located in the `datasets` directory.

To run the script, `CollectNovakDjokovic2019stats.py`, you'll need to go to
https://developer.sportradar.com/docs/read/tennis/Tennis_v2#daily-live-results
in order to sign up for a free trial and obtain an API key. Once you've retrieved
that key, create a `my_api_key.json` inside the `data` directory formatted as follows:

```
{"api_key" : "<your API key here>"}
```

Note that the free trial only allows 1 query/second which is why I have waits
throughout my code. 