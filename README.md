There are 2 parts to the code in this project

.

In the first part, Statcast data is used to create the Run Expectancy matrix based on the 24 base-out states

.

![Screenshot 2023-07-29 154019](https://github.com/josephmontes/Statcast.RE24/assets/125607783/f944d0e3-541b-483a-8d2e-a08da7a49bc2)

.


In the second part, the value of each base-out state is used to create a column in the Statcast data that estimates the change in run expectancy for each at bat using the RE24 formula: 



Run Expectancy in End State - Run Exepectancy in Beginning State + Runs Scored

.

Here is an example from the mutated dataset featuring a random half inning

RUNS_VALUE being the change in run expectancy

![Screenshot 2023-07-29 161946](https://github.com/josephmontes/Statcast.RE24/assets/125607783/75d9b9c7-6207-4fbe-a29b-0137042d5c43)

.

After the change in run expectancy for each play is estimated, players can be evaluated by the degree of total change in run expectancy that occurs when they are on the mound or at the plate in each base-out state

.

In my database, I have pitcher names so I chose the following 3 pitchers from 2022 to evaluate: Gerrit Cole, Cole Irvin, Sandy Alcantara

.

First, the amount of times they faced each base-out state is displayed 


![Screenshot 2023-07-29 154903](https://github.com/josephmontes/Statcast.RE24/assets/125607783/16293b5a-6c6a-435f-b8e3-df7922b17b7f)


Along with the degree of change in run expectancy for each state

![Screenshot 2023-07-29 154958](https://github.com/josephmontes/Statcast.RE24/assets/125607783/195d22b3-e3a9-4bbf-9517-2633e2e53c08)

.



.

This can be further broken down into the amount of times a player was faced with each particular base-out state and how they performed in each state

.

A visualization of how the change in run expectancy is distributed by state


![Screenshot 2023-07-29 163549](https://github.com/josephmontes/Statcast.RE24/assets/125607783/168024a0-105d-45d7-b500-802d07b4699e)


![Screenshot 2023-07-29 163536](https://github.com/josephmontes/Statcast.RE24/assets/125607783/bbdc4fcd-dd60-41a5-afc6-4629b15ffa74)


![Screenshot 2023-07-29 163524](https://github.com/josephmontes/Statcast.RE24/assets/125607783/e604e84b-4730-4f91-ab26-c257154bee58)




.

Finally, the amount of change in run exepectancy for each state can be summed together to determine the total amount of change in run exepectancy occured when each pitcher was on the mound.


![Screenshot 2023-07-29 155035](https://github.com/josephmontes/Statcast.RE24/assets/125607783/06b3a937-8851-4258-a233-47e3327ffdf0)


Statcast data scraped from baseballr::statcast_search_pitchers()

.

Unfortunately, there were a lot of missing values scattered across multiple important variables in my data

.

The book 'Analyzing Baseball Data with R' has a chapter that can help build this, but they used Retrosheet data

