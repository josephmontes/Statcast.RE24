There are 2 parts to the code for this project:

In the first part, pitch by pitch Statcast data is used to create a Run Expectancy matrix using the 24 base-out states


![Screenshot 2023-07-29 154019](https://github.com/josephmontes/Statcast.RE24/assets/125607783/f944d0e3-541b-483a-8d2e-a08da7a49bc2)



In the second part, the value of each base-out state is used to create a column in the Statcast data, 'RUNS_VALUE' that estimates the change in run expectancy for each at bat using the RE24 formula:

Run Expectancy in End State - Run Exepectancy in Beginning State + Runs Scored

.

Here is an example from the mutated dataset featuring a random half inning

![Screenshot 2023-07-29 161946](https://github.com/josephmontes/Statcast.RE24/assets/125607783/75d9b9c7-6207-4fbe-a29b-0137042d5c43)






After the change in run expectancy for each play is estimated, players can be evaluated by the degree of total change in run expectancy that occurs when they are on the mound or at the plate
- It only says the pitcher's name in my particular Statcast dataset so I chose the following 3 pitchers from 2022 to evaluate: Cole Irvin, Luis Severino, Corbin Burnes

.

First, the amount of times they faced a batter in each base state is displayed


![Screenshot 2023-08-01 171027](https://github.com/josephmontes/Statcast.RE24/assets/125607783/7d9ffc80-9a70-41d1-af27-9dd11cd5be99)


Along with the cumulative sum of the change in run expectancy


![Screenshot 2023-08-01 171147](https://github.com/josephmontes/Statcast.RE24/assets/125607783/1e4dc14f-2067-4d0c-a3cd-de34f28bc287)



Next, a strip chart can be created to visualize each individual change in run expectancy as they are distributed by base state for each player


![Screenshot 2023-08-01 171223](https://github.com/josephmontes/Statcast.RE24/assets/125607783/7fe67b6c-ca94-44a0-90b8-91c939854a5b)


![Screenshot 2023-08-01 171241](https://github.com/josephmontes/Statcast.RE24/assets/125607783/63786867-99b7-4aba-a1a9-7ea258d25376)


![Screenshot 2023-08-01 171258](https://github.com/josephmontes/Statcast.RE24/assets/125607783/92cf95ef-c50c-4a8d-b066-fad2bf75cd62)



Then, RE24 can be calculated by summing together every change in run expectancy for each pitcher 

![Screenshot 2023-08-05 202347](https://github.com/josephmontes/Statcast.RE24/assets/125607783/cfc5fbf7-e5d0-452c-a7e3-91a61a75fc33)

Typical RE24 is a counting stat but there is code included to make it into a rate-type stat too

![Screenshot 2023-08-05 202415](https://github.com/josephmontes/Statcast.RE24/assets/125607783/0e91a264-bafc-4b71-b713-0b198395b835)


!! It is important to note that for pitchers, the cumulative sum of changes in run expectancy will result in a negative number for good pitchers and positive for bad pitchers, so it needs to be multipled by -1 to resemble the typical RE24 stat format shown below !!


![Screenshot 2023-08-04 155117](https://github.com/josephmontes/Statcast.RE24/assets/125607783/5a42e994-c162-4592-b4e3-ef44f46e00c9)




Finally, the code features a way to make official leaderboards for RE24 & my rated version of RE24

![Screenshot 2023-08-05 202450](https://github.com/josephmontes/Statcast.RE24/assets/125607783/afb24311-e403-4324-8e60-d60f190e08a9)


![Screenshot 2023-08-05 202517](https://github.com/josephmontes/Statcast.RE24/assets/125607783/87f6ccc6-9ccb-4640-b816-ccc914570159)


Chapter 5 of the book 'Analyzing Baseball Data with R' guided me in building out this project, but they use Retrosheet data instead of Statcast

.

Statcast data was scraped in R using baseballr::statcast_search_pitchers()

.

Please feel free to email me at josephmontes.baseball@gmail.com with any questions, suggestions, or comments about this project. I can also share the large CSV file containing the relevant Statcast pitch by pitch data.
