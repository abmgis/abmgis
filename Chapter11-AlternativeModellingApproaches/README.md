# Chapter 11 - Alternative Modelling Approaches

This folder includes the accompanying resources for the chatper. For full book details, see: [http://www.abmgis.org/](http://www.abmgis.org/).

## Introduction

Agent-based modelling is one of the most popular approaches used in social and spatial simulation.  However, there are several other alternative approaches that are available to the researcher including Cellular Automata (CA), Microsimulation, Discreet Event Simulation (DES), System Dynamics (SD) and Spatial Interaction models. 

This chapter presents an overview of these other approaches giving simple examples on how they can be used and summarising the main differences between them.  To compare these models, they are applied to the same issue, the spread of a disease using a Susceptible-Infected-Recovered (SIR) epidemic model.  This shows that while the same general patterns emerge, the reasons for this are very different.

## Lecture Slides

The lecture slides for this chapter are available here: [Chapter 11 Lecture Slides](./Chapter11.pptx). These act as a teaching aid for the chapter (with links to other resources).

## This Directory

You will find 3 example models of for CA, SD and DES. 

1. **A Cellular Automata** (CA) model: The Game of Life model ([CA_LifeModifed_Example.nlogo](Models/CA_LifeModifed_Example.nlogo))
1. **A Discreet Event Simulation** (DES): [DES_Airport_Queue_Example.nlogo](Models/DES_Airport_Queue_Example.nlogo)
1. **A System Dynamics** (SD) Model: [System_Dynamics_Wolf_Sheep_Predation_Example.nlogo](Models/System_Dynamics_Wolf_Sheep_Predation_Example.nlogo)

More details about these models can be found [here](Models/README.md) 

Furthermore, to compare the differnet modeling approaches to the same issue, in this directory you will also find 4 models that look at the spread of a disease:

* **Cellular Automata** ([SIR_CA.nlogo](Models/SIR_Models/SIR_CA.nlogo))
* **Discreet Event Simulation** ([SIR_DES.nlogo](Models/SIR_Models/SIR_DES.nlogo))
* **System Dynamics Model** ([SIR_SD.nlogo](Models/SIR_Models/SIR_SD.nlogo))
* **Agent-based Model** ([SIR_ABM.nlogo](Models/SIR_Models/SIR_ABM.nlogo))

More details about these models can be found [here](Models/SIR_Models/README.md) 

# Other Modeling Approaches

Due to time and space limations, no models were created for Spatial Interaction or Microsimulation techniques. Readers who wish to gain more hands on experience with these are encouraged to keep reading below. 

## Spatial Interation Models: 

For useful set of practicals and material on Spatial Interaction models (and how to implement them using R), readers are refered to <https://rpubs.com/adam_dennett> 


## Microsimulation:

For a good summary of microsimulation, its application and its difference to agent-based models please see:

* **Birkin, M. and Wu, B. (2012)**, ’[A Review of Microsimulation and Hybrid Agent-Based Approaches](https://link.springer.com/chapter/10.1007/978-90-481-8927-4_3)’, in Heppenstall, A., Crooks, A.T., See, L.M. and Batty, M. (eds.), *Agent-based Models of Geographical Systems*, Springer, New York, NY, pp. 51-68.

For a good discussion of spatial microsimulation along with how to use R to carry out such modeling, please see:

* **Lovelace, R. and Dumont, M. (2016)**. *Spatial Microsimulation with R*. CRC Press, Boca Raton, FL. 

More inforation about the book can be found here: <http://spatial-microsim-book.robinlovelace.net/> along with the GitHub repository that hosts the code and data used <https://github.com/Robinlovelace/spatial-microsim-book>.