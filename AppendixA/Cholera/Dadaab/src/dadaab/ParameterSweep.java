///*
// * To change this template, choose Tools | Templates
// * and open the template in the editor.
// */
//package dadaab;
//
///**
// *
// * @author ates
// */
//public class ParameterSweep {
//
//    public static int numRuns = 2; // the number of times to run each parameter setting
//    public static int numSteps = 43200; // the number of ticks to iterate each simulation
//
//    public static void main(String[] args) {
//
//// set up the list of values over which you will sweep
//       int[] popvals = new int[]{5000, 10000, 25000,50000, 100000,200000,500000};
//
//      //  double [] rainfall =  new double []{0.1,0.5,1,3};
//        
//        
//// iterate over the population values
//        //for (int popcount : popvals) {
//        
//        // vibrioCholeraePerHealthyPerson
//            for (int popcount : popvals) {
//
//// presumably you want to run the simulation multiple times with each
////parameter setting?
//            for (int run = 0; run < numRuns; run++) {
//
//// create a new instance of the simulation
//                Dadaab d = new Dadaab(System.currentTimeMillis(),args);
//
//// set the relevant parameters and begin the simulation
//                d.params.global.setInitialRefugeeNumber(popcount);
//                d.start();
//                for (int i = 0; i < numSteps; i++) {
//                    d.schedule.step(d);
//                }
//// once the simulation has gone through as many steps as you require, clean up
//                d.finish();
//            }
//        }
//
//
////////////////
//    }
//}