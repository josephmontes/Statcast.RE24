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


![Screenshot 2023-08-01 171027](https://github.com/josephmontes/Statcast.RE24/assets/125607783/7d9ffc80-9a70-41d1-af27-9dd11cd5be99)


Along with the degree of change in run expectancy for each state

![Screenshot 2023-08-01 171147](https://github.com/josephmontes/Statcast.RE24/assets/125607783/1e4dc14f-2067-4d0c-a3cd-de34f28bc287)

.



.

This can be further broken down into the amount of times a player was faced with each particular base-out state and how they performed in each state

.

A visualization of how the change in run expectancy is distributed by state


![Screenshot 2023-08-01 171223](https://github.com/josephmontes/Statcast.RE24/assets/125607783/7fe67b6c-ca94-44a0-90b8-91c939854a5b)


![Screenshot 2023-08-01 171241](https://github.com/josephmontes/Statcast.RE24/assets/125607783/63786867-99b7-4aba-a1a9-7ea258d25376)


![Screenshot 2023-08-01 171258](https://github.com/josephmontes/Statcast.RE24/assets/125607783/92cf95ef-c50c-4a8d-b066-fad2bf75cd62)



.

Finally, the amount of change in run exepectancy for each state can be summed together to determine the total amount of change in run exepectancy occured when each pitcher was on the mound.


![Screenshot 2023-08-01 171335](https://github.com/josephmontes/Statcast.RE24/assets/125607783/2a2e0d71-b534-4f14-ac79-57075c39655f)

.

![Screenshot 2023-08-01 171352](https://github.com/josephmontes/Statcast.RE24/assets/125607783/1ed2251f-d6b8-4622-9832-bc6717535090)

.


![Screenshot 2023-08-01 172117](https://github.com/josephmontes/Statcast.RE24/assets/125607783/d6a93147-624d-43f8-bfbd-f7c76f1e11be)

.

![Screenshot 2023-08-01 172136](https://github.com/josephmontes/Statcast.RE24/assets/125607783/444baaa7-971d-402f-998e-c3a6d9e11e76)


Statcast data scraped from baseballr::statcast_search_pitchers()

.

Unfortunately, there were a lot of missing values scattered across multiple important variables in my data

.

The book 'Analyzing Baseball Data with R' has a chapter that can help build this, but they used Retrosheet data

