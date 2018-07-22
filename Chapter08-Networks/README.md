# Chapter 8 - Networks


## Introduction

Networks play a critical role in our lives in terms of physical networks we use to navigate upon, our social networks and more recently how we communicate via cyber networks (e.g. social media). This chapter provides a brief introduction to such networks and shows how they can be integrated into agent-based models. Importantly, a model is also introduced that demonstrates how to navigate agents along a physical road network (this is a common requirement for spatially-explicit agent-based models). 

## Models in the Chapter

* **Undirected Network Demo**: A simple example of how to create a undirected network in NetLogo
* **[Directed Network Demo](Models)**: A simple example of how to create a directed network in NetLogo
* **[Random Network Example](Models)**: A simple example of how to create a random networks in NetLogo
* Networks in NetLogo:
* **[Preferential Attachment](Models)**: Demostrates how networks can grow where new nodes have a greter chance to be connected to nodes which have a high degree (i.e. number of conncetions
* **[GMU-Roads](Models/GMU-Roads)**: Demonstrates how to use the A-star algorithm, implemented in NetLogo to move agents along a vector road network.
* **[GMU-Social](Models/GMU-Social])**: Extends the GMU-Roads model to show how one can link social and physical networks 
* **[From Cyber Space Opinion Leaders and the Spread of Anti-Vaccine Extremism to Physical Space Disease Vulnerable Clusters](Models)**: Model explores how does ones online social (i.e. cyber) network influences a persons willingness to be vaccinated, and how does this choice impact the spread of a disease in the physical environment.

## References

The Preferential Attachment is taken directly from NetLogo:

* Wilensky, U. (2005). NetLogo Preferential Attachment model. <http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment>. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

The Random Network Example model is taken directly from NetLogo:

* Wilensky, U., Rand, W. (2008). NetLogo Random Network model. <http://ccl.northwestern.edu/netlogo/models/RandomNetwork>. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

The Cyber Space Opinion Leaders model is taken directly from:

* Yuan, X. and Crooks, A.T. (2017), [From Cyber Space Opinion Leaders and the Spread of Anti-Vaccine Extremism to Physical Space Disease Outbreaks](https://link.springer.com/chapter/10.1007/978-3-319-60240-0_14), in Lee, D., Lin, Y., Osgood, N. and Thomson, R. (eds.) *Proceedings of the 2017 International Conference on Social Computing, Behavioral-Cultural Modeling and Prediction and Behavior Representation in Modeling and Simulation*, Springer, New York, NY., pp. 114-119.

## Links

* The NetLogo links documentation <https://ccl.northwestern.edu/netlogo/docs/programming.html#links> is very comprehensive and worth reading
* NetLogo’s Network Extension toolkit <https://github.com/NetLogo/Network-Extension>