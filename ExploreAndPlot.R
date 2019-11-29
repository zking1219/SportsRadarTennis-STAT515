#==================================================
# Script to explore and plot data from Novak
# Djokovic's 2019 season
#==================================================

# Change this to reflect wherever you've cloned this repo on your machine
#setwd("/Users/zackkingbackup/Documents/Grad Schools/GMU_Masters/STAT515/RedesignProject1/SportsRadarTennis-STAT515")
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
ggplot(bar_tibble2, aes(x=surface, y=ace_percentage*100, fill=is_winner)) + 
  geom_bar(position=position_dodge(.9), colour="black", stat="identity") +
  geom_errorbar(position=position_dodge(.9), width=.25, aes(ymin=100*(ace_percentage-ci), ymax=100*(ace_percentage+ci))) + 
  ggtitle("Novak Djokovic 2019 Ace Percentage 95% CIs") +
  labs(x="Court Surface", y="Ace Percentage") +
  hw

# Mild problem - Djokovic's only grass tournament was wimbledon... and he won it so there are no losses
# Solution - Append a row of zeros for the missing record identified by surface=grass, is_winner=FALSE
bar_tibble3 <- rbind(bar_tibble2[1,], c("Grass",FALSE,0,0,0,0,0,0), bar_tibble2[c(2:5),])
bar_tibble3$ace_percentage = as.numeric(bar_tibble3$ace_percentage)
bar_tibble3$ci = as.numeric(bar_tibble3$ci)

ggplot(bar_tibble3, aes(x=surface, y=ace_percentage*100, fill=is_winner)) + 
  geom_bar(position=position_dodge(.9), colour="black", stat="identity") +
  geom_errorbar(position=position_dodge(.9), width=.25, aes(ymin=100*(ace_percentage-ci), ymax=100*(ace_percentage+ci))) + 
  ggtitle("Novak Djokovic 2019 Ace Percentage 95% CIs") +
  labs(x="Court Surface", y="Ace Percentage") +
  hw

# There's probably something cool I can do using facets as shown in #5 here 
# http://r-statistics.co/ggplot2-Tutorial-With-R.html
# perhaps to split by surface and/or win-loss
# Maybe showing data temporaly in a facet_grid could go well

# First compute the Dominance Rating (DR) = % pts won returning / % pts lost serving
tibble2 <- nddata[names(nddata) %in% c("ace_percentage","double_fault_percentage","first_serve_pct","first_serve_points_won_pct","second_serve_points_won_pct","is_winner","surface",
                                       "opp_service_points_won","service_points_won","opp_receiver_points_won","receiver_points_won")]

get_DR <- function(spw, ospw, rpw, orpw)
{
  pct_return_won = rpw / (ospw + rpw)
  pct_serve_lost = orpw / (spw + orpw)
  return (pct_return_won / pct_serve_lost)
}

tibble2$DR <- apply(tibble2[,c('service_points_won','opp_service_points_won','receiver_points_won','opp_receiver_points_won')], 1, function(x) get_DR(x[1],x[2],x[3],x[4]))

# Plot DR v. ace_percentage 
ggplot(tibble2, aes(x=DR,y=ace_percentage*100)) + 
  geom_point(aes(shape=surface,colour=is_winner)) +
  hw

gg1 <- ggplot(tibble2, aes(x=DR,y=ace_percentage*100)) + 
  geom_point(aes(colour=is_winner)) +
  hw

# Don't love that, lets try the facet_grid breaking apart by surface
gg1 + facet_wrap( ~ surface, ncol=3) + coord_cartesian(xlim=c(0, 4))

# This is better; lets map is_winner to match_result = {"Win", "Loss"}
# and fix our labels, add a title
map_to_mr <- function(is_winner)
{
  if (is_winner) result = "Win" else result = "Loss"
  return(result)
}
tibble2$match_result = apply(tibble2[,c("is_winner")], 1, function(x) map_to_mr(x[1]))
ggplot(tibble2, aes(x=DR,y=ace_percentage*100)) + 
  geom_point(aes(colour=match_result)) +
  hw + 
  facet_wrap( ~ surface, ncol=3) + 
  coord_cartesian(xlim=c(0, 4)) +
  labs(x="Dominance Rating",y="Ace Percentage") +
  ggtitle("Novak Djokovic 2019 DR v. Ace Percentage")

# Now do it again for first serve pct
ggplot(tibble2, aes(x=DR,y=first_serve_pct*100)) + 
  geom_point(aes(colour=match_result)) +
  hw + 
  facet_wrap( ~ surface, ncol=3) + 
  coord_cartesian(xlim=c(0, 4),ylim=c(0,100)) +
  labs(x="Dominance Rating",y="First Serve Percentage") +
  ggtitle("Novak Djokovic 2019 DR v. First Serve percentage")

# For double fault pct
ggplot(tibble2, aes(x=DR,y=double_fault_percentage*100)) + 
  geom_point(aes(colour=match_result)) +
  hw + 
  facet_wrap( ~ surface, ncol=3) + 
  coord_cartesian(xlim=c(0, 4)) +
  labs(x="Dominance Rating",y="Double Fault Percentage") +
  ggtitle("Novak Djokovic 2019 DR v. Double Fault percentage")

# What about using log(DR) v. Ace percentage? 
tibble2$LDR <- log(tibble2$DR)
ldr_ap_stack <- ggplot(tibble2, aes(x=LDR,y=ace_percentage*100)) + 
  geom_point(aes(colour=match_result)) +
  hw + #theme(legend.position="none") +
  facet_wrap( ~ surface, ncol=3) +
  labs(x="",y="Ace %") + 
  ggtitle("Novak Djokovic 2019 Matches") +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), legend.position = "none",
        axis.title.y = element_text(angle = 0))

ldr_ap <- ldr_ap_stack + 
  labs(x="ln(Dominance Rating)",y="Ace Percentage") +
  ggtitle("Novak Djokovic 2019 ln(DR) v. Ace percentage") #+ 
  #theme(legend.position = "right")

ldr_ap

# ln(DR) v. First Serve percentage
ldr_fsp_stack <- ggplot(tibble2, aes(x=LDR,y=first_serve_pct*100)) + 
  geom_point(aes(colour=match_result)) +
  hw +
  facet_wrap( ~ surface, ncol=3) + 
  coord_cartesian(ylim=c(0, 100)) +
  labs(x="",y="First Serve %") +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), strip.background = element_blank(),
        strip.text.x = element_blank(), legend.position = "none",
        axis.title.y = element_text(angle = 0)) 

ldr_fsp <- ldr_fsp_stack +
  labs(x="ln(Dominance Rating)",y="First Serve Percentage") +
  ggtitle("Novak Djokovic 2019 ln(DR) v. First Serve percentage")

ldr_fsp

# ln(DR) v. Double Fault percentage
ldr_dfp_stack <- ggplot(tibble2, aes(x=LDR,y=double_fault_percentage*100)) + 
  geom_point(aes(colour=match_result)) +
  hw +# theme(legend.position="none") +
  facet_wrap( ~ surface, ncol=3) +
  labs(x="ln(Dominance Rating)",y="Double Fault %") +
  theme(strip.background = element_blank(),
  strip.text.x = element_blank(), legend.position = "bottom",
  legend.title = element_blank(), axis.title.y = element_text(angle = 0))
  
ldr_dfp <- ldr_dfp_stack + 
  labs(x="ln(Dominance Rating)",y="Double Fault Percentage") +
  ggtitle("Novak Djokovic 2019 ln(DR) v. Double Fault percentage") #+ 
  #theme(legend.position = "right")

ldr_dfp

# I prefer using the ln(Dominance Rating), you can still tell where
# the midpoint of the scale is because ln(1) = 0
# Now lets stack the 3 above plots
library(grid)
grid.newpage()
grid.draw(rbind(ggplotGrob(ldr_ap_stack), ggplotGrob(ldr_fsp_stack), 
                ggplotGrob(ldr_dfp_stack), 
                size = "last"))

# Try ggarrange to fix this nonsense
# http://www.sthda.com/english/articles/24-ggpubr-publication-ready-plots/81-ggplot2-easy-way-to-mix-multiple-graphs-on-the-same-page/

# ln(DR) v. First Serve Win %
ldr_fswp_stack <- ggplot(tibble2, aes(x=LDR,y=first_serve_points_won_pct*100)) + 
  geom_point(aes(colour=match_result)) +
  hw +
  facet_wrap( ~ surface, ncol=3) + 
  coord_cartesian(ylim=c(0, 100)) +
  labs(x="",y="First Serve\nPoints Won %") +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), strip.background = element_blank(),
        strip.text.x = element_blank(), legend.position = "none",
        axis.title.y = element_text(angle = 0)) 

# ln(DR) v. Second Serve Win %
ldr_sswp_stack <- ggplot(tibble2, aes(x=LDR,y=second_serve_points_won_pct*100)) + 
  geom_point(aes(colour=match_result)) +
  hw +
  facet_wrap( ~ surface, ncol=3) + 
  coord_cartesian(ylim=c(0, 100)) +
  labs(x="",y="Second Serve\nPoints Won %") +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), strip.background = element_blank(),
        strip.text.x = element_blank(), legend.position = "none",
        axis.title.y = element_text(angle = 0)) 

grid.newpage()
grid.draw(rbind(ggplotGrob(ldr_ap_stack), ggplotGrob(ldr_fsp_stack),
                ggplotGrob(ldr_fswp_stack), ggplotGrob(ldr_sswp_stack),
                ggplotGrob(ldr_dfp_stack),
                size = "last"))

# I want a splom showing distributions of my variables
offDiag <- function(x,y,...){
  panel.grid(h=-1,v=-1,...)
  panel.hexbinplot(x,y,xbins=15,...,border=gray(.7),
                   trans=function(x)x^.5)
  panel.loess(x , y, ..., lwd=2,col='red')
}
onDiag <- 
  function(x, ...){
    yrng <- current.panel.limits()$ylim
    d <- density(x, na.rm=TRUE)
    d$y <- with(d, yrng[1] + 0.95 * diff(yrng) * y / max(y) )
    panel.lines(d,col=rgb(.83,.66,1),lwd=2)
    diag.panel.splom(x, ...)
  }
#install.packages("ellipse")
library(lattice)
library(hexbin)
quartz(width=9,height=9) 
splom(tibble2[,6:10], type=c("g","p"),as.matrix=TRUE,
      varnames=c("Double\nFault %",
                 "Ace %",
                 "1st Serve\npts won %",
                 "2nd Serve\npts won %",
                 "1st Serve %"),
      xlab='',
      # main=paste("Iris Data:  Green=Setosa, ",  
      #            "Red=Versicolor, Cyan=Virginica",sep=""),
      pscale=3, varname.cex=0.8,axis.text.cex=0.65,
      axis.text.col="purple",axis.text.font=2,
      axis.line.tck=.5, pch=21,
      col="black",lwd=3
)

quartz(width=9,height=9) 
splom(tibble2[,c(6:10,12)], as.matrix = TRUE,
      xlab = '',main = "Djokovic 2019 Data ",
      varnames=c("Double\nFault %",
                 "Ace %",
                 "1st Serve\npts won %",
                 "2nd Serve\npts won %",
                 "1st Serve %",
                 "Dominance\nRating (DR)"),
      pscale = 0, varname.col = "red",
      varname.cex = 0.56, varname.font = 2,
      axis.text.cex = 0.4, axis.text.col = "red",
      axis.text.font = 2, axis.line.tck = .5,
      panel = function(x,y,...) {
        panel.grid(h = -1,v = -1,...)
        panel.hexbinplot(x,y,xbins = 12,...,
                         border = gray(.7),
                         trans = function(x)x^1)
        panel.loess(x , y, ...,
                    lwd = 2,col = 'purple')
      },
      diag.panel = function(x, ...){
        yrng <- current.panel.limits()$ylim
        d <- density(x, na.rm = TRUE)
        d$y <- with(d, yrng[1] + 0.95 * diff(yrng) * y / max(y) )
        panel.lines(d,col = gray(.8),lwd = 2)
        diag.panel.splom(x, ...)
      }
)

# I want a bubble chart that uses Ace % for the size and plots DR v. 1st Serve %
ggplot(tibble2, aes(x=LDR,y=first_serve_pct*100,size=ace_percentage*100,fill=match_result)) + 
  geom_point(alpha=0.5, shape=21) +
  hw + 
  facet_wrap( ~ surface, ncol=3) + 
  labs(x="ln(Dominance Rating)",y="First Serve Percentage") +
  coord_cartesian(ylim=c(0, 100)) +
  ggtitle("Novak Djokovic 2019 ln(DR) v. First Serve Percentage")
  #theme(legend.title = element_blank()

# Bubble chart for First Serve % v. First Serve % points won w/ LDR as bubble size
quartz(width=9,height=6)
ggplot(tibble2, aes(x=first_serve_points_won_pct*100,y=first_serve_pct*100,size=LDR,fill=match_result)) + 
  geom_point(alpha=0.5, shape=21) +
  hw + 
  facet_wrap( ~ surface, ncol=3) + 
  labs(x="Percent First Serve Points Won",y="First Serve Percentage") +
  coord_cartesian(ylim=c(0, 100),xlim=c(0,100)) +
  ggtitle("Novak Djokovic 2019 Percentage First Serve Points Won\nv. First Serve Percentage") +
  theme(legend.title = element_blank())

lnDRmod <- lm(LDR ~ . , data=tibble2[,c(6:10,14)] )

