/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package kibera;

/**
 *
 * @author ates
 */
public class ParameterSweep {

    public static int numRuns = 1; // the number of times to run each parameter setting
    public static int numSteps = 11000; // the number of ticks to iterate each simulation

    public static void main(String[] args) {

    // set up the list of values over which you will sweep
    double[] aggressionThresholds = new double[] { 0.0, .2, .4, .6, .8, 1.0};
    double[] preference = new double[] {0,.5,1};
    int[] rumor = new int[] {0,10,500,1000};
    
    for (double aggress : aggressionThresholds) {

    	// presumably you want to run the simulation multiple times with each
    	//parameter setting?
    	for (int run = 0; run < numRuns; run++) {

    		// create a new instance of the simulation
    		Kibera kibera = new Kibera(System.currentTimeMillis());

    		// set the relevant parameters and begin the simulation
    		kibera.aggressionThreshold = aggress;
    		kibera.start();
    		for (int i = 0; i < numSteps; i++) {
    			kibera.schedule.step(kibera);
            }
    		// once the simulation has gone through as many steps as you require, clean up
            kibera.finish();
            }
        }
    
    /*for (double p : preference) {

    	// presumably you want to run the simulation multiple times with each
    	//parameter setting?
    	for (int run = 0; run < numRuns; run++) {

    		// create a new instance of the simulation
    		Kibera kibera = new Kibera(System.currentTimeMillis());

    		// set the relevant parameters and begin the simulation
    		kibera.preferenceforLivingNearLikeNeighbors = p;
    		kibera.start();
    		for (int i = 0; i < numSteps; i++) {
    			kibera.schedule.step(kibera);
            }
    		// once the simulation has gone through as many steps as you require, clean up
            kibera.finish();
            }
        }*/
    
    /*for (int r : rumor) {

    	// presumably you want to run the simulation multiple times with each
    	//parameter setting?
    	for (int run = 0; run < numRuns; run++) {

    		// create a new instance of the simulation
    		Kibera kibera = new Kibera(System.currentTimeMillis());

    		// set the relevant parameters and begin the simulation
    		kibera.numResidentsHearRumor = r;
    		kibera.start();
    		for (int i = 0; i < numSteps; i++) {
    			kibera.schedule.step(kibera);
            }
    		// once the simulation has gone through as many steps as you require, clean up
            kibera.finish();
            }
        }
    
    /*for (int pop : popvals) {

    	// presumably you want to run the simulation multiple times with each
    	//parameter setting?
    	for (int run = 0; run < numRuns; run++) {

    		// create a new instance of the simulation
    		Kibera kibera = new Kibera(System.currentTimeMillis());

    		// set the relevant parameters and begin the simulation
    		kibera.numResidents = pop;
    		kibera.start();
    		for (int i = 0; i < numSteps; i++) {
    			kibera.schedule.step(kibera);
            }
    		// once the simulation has gone through as many steps as you require, clean up
            kibera.finish();
            }
        }*/
    
    }
}
