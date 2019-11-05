#==================================================
# Script to explore and plot data from Novak
# Djokovic's 2019 season
#==================================================

# Change this to reflect wherever you've cloned this repo on your machine
setwd("/Users/iaa211/Documents/ContinuedEducation/GMU-Masters/STAT515/Redesign1/SportsRadarTennis-STAT515")

library(tidyverse)
source('hw.R') # Instructor provided ggplot theme
source('ggplotHelpers.R') # cookbook-r.com helper functions

nddata <- as_tibble(read_csv("datasets/NovakDjokovic2019matchStats.csv"))

# Create a subset using columns that represent Ace Pct, DF Pct, 1st In Pct, 
# 1st win Pct, and 2nd win Pct 
# So we'll cbind together: "ace_percentage", "double_fault_percentage", "first_serve_pct",
# "first_serve_points_won_pct", "second_serve_points_won_pct"
# and we'll need "is_winner" and "surface" in case we want to color-code or 
# break down splits as is done on https://tennisvisuals.com/
# in order to create bar graphs with errorbars
bar_tibble1 <- nddata[names(nddata) %in% c("ace_percentage","double_fault_percentage","first_serve_pct","first_serve_points_won_pct","second_serve_points_won_pct","is_winner","surface")]

bar_tibble2 <- summarySEwithin(bar_tibble1, measurevar="ace_percentage", withinvars=c("surface","is_winner"))

library(ggplot2)
ggplot(bar_tibble2, aes(x=surface, y=ace_percentage, fill=is_winner)) + 
  geom_bar(position=position_dodge(.9), colour="black", stat="identity") +
  geom_errorbar(position=position_dodge(.9), width=.25, aes(ymin=ace_percentage-ci, ymax=ace_percentage+ci)) + 
  ggtitle("Novak Djokovic 2019 Ace Percentage 95% CIs") +
  labs(x="Court Surface", y="Ace Percentage") +
  hw

# Mild problem - Djokovic's only grass tournament was wimbledon... and he won it so there are no losses
# Solution - Append a row of zeros for the missing record identified by surface=grass, is_winner=FALSE
bar_tibble3 <- rbind(bar_tibble2[1,], c("Grass",FALSE,0,0,0,0,0,0), bar_tibble2[c(2:5),])
bar_tibble3$ace_percentage = as.numeric(bar_tibble3$ace_percentage)
bar_tibble3$ci = as.numeric(bar_tibble3$ci)

ggplot(bar_tibble3, aes(x=surface, y=ace_percentage, fill=is_winner)) + 
  geom_bar(position=position_dodge(.9), colour="black", stat="identity") +
  geom_errorbar(position=position_dodge(.9), width=.25, aes(ymin=ace_percentage-ci, ymax=ace_percentage+ci)) + 
  ggtitle("Novak Djokovic 2019 Ace Percentage 95% CIs") +
  labs(x="Court Surface", y="Ace Percentage") +
  hw

# There's probably something cool I can do using facets as shown in #5 here 
# http://r-statistics.co/ggplot2-Tutorial-With-R.html
# perhaps to split by surface and/or win-loss
# Maybe showing data temporaly in a facet_grid could go well

