# Chapter 6 - Integrating Agent-Based Modelling and GIS

This folder includes the accompanying resources for the chatper. For full book details, see: [http://www.abmgis.org/](http://www.abmgis.org/).

## Introduction

Building on previous chapters outlining the fundamentals of GIS and agent-based modelling, what are the benefits to linking these approaches? How is this undertaken? This chapter will explain loose and tight coupling, critiquing the relative advantages and disadvantages of both. We present an overview of open source toolkits that can be used for the creation of geographically explicit agent-based models, before providing a critical look at where and how GIS and ABM should be combined, offering practical advice on best practice.

In the folder you will find:

* [**PatchSize Model**](Models/PatchSize): An example of setting the patch size of NetLogo 
* **[UrbanGrowth](Models/UrbanGrowth)**: The model demonstrates how several raster layers can be used to initialize a NetLogo model and explore urban growth.
* **[Rainfall Model](Models/Rainfall)**: An exaple of how to use a digital elevation model (DEM) and make agents follow a gradient. 
	* [**RainFall_3D**](Models/RainFall_3D): An extension of the rainfall model to 3D (using Netlogo 3D.
* [**Pedestrian_Model_Grid**](Models/Pedestrian_Model_Grid): Simple example of agents following a gradient to exit a room.
* [**Pedestrians_Exiting_Building**](Models/Pedestrians_Exiting_Building): Simple pedestrian evacauion model based on a CAD file.
* [**Segregation_DC_1**](Models/Segregation_DC_1): Segregation model where each vector polygon is an agent.
* [**Segregation_DC_2**](Models/Segregation_DC_2): Builds on Segregation_DC_1 but has multiple agents per polygon.
* [**SegregationTutorial**](Models/SegregationTutorial: Tutorial on how to build Segregation_DC_1  (includes both a powerpoint and pdf).


## Links

NetLogo’s GIS Extension: <https://ccl.northwestern.edu/netlogo/docs/gis.html>

NetLogo's 3D Information: <https://ccl.northwestern.edu/netlogo/docs/3d.html>