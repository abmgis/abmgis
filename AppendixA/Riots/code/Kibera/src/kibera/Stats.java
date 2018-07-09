//package masoncsc.util;
package kibera;

import ec.util.MersenneTwisterFast;

/**
 * This class provides some useful functions for certain statistical operations, including:
 * - Drawing from a lognormal distribution.
 * 
 * @author Joey Harrison
 * 
 */
public class Stats
{
	static private double mean = 0;
	static private double stdev = 0;
	
	static public double calcLognormalMu(double mean, double stdev) {
		return Math.log(mean) - 0.5 * Math.log(1.0 + (stdev*stdev) / (mean*mean));
	}
	
	static public double calcLognormalSigma(double mean, double stdev) {
		return Math.sqrt(Math.log((stdev*stdev) / (mean*mean) + 1.0));
	}
	
	static public void setMean(double mean) {
		Stats.mean = mean;
	}
	
	static public void setStdev(double stdev) {
		Stats.stdev = stdev;
	}
	
	/**
	 * Convert a random variable drawn from a normal (Gaussian) distribution to
	 * one that is lognormally distributed.
	 * @param mu 
	 * @param sigma
	 * @param normalVal random number drawn from a normal distribution.
	 * @return
	 */
	static public double normalToLognormal(double mu, double sigma, double normalVal) {
		return Math.exp(mu + sigma*normalVal);
	}
	
	public static void main(String[] args) {
		MersenneTwisterFast random = new MersenneTwisterFast();		// when using MASON, this is already in SimState
		double mean = Stats.mean;
		double stdev = Stats.stdev;
		double mu = Stats.calcLognormalMu(mean, stdev);
		double sigma = Stats.calcLognormalSigma(mean, stdev);
		
		/*for (int i = 0; i < 1000; i++) {
			double x = Stats.normalToLognormal(mu, sigma, random.nextGaussian());		// This is how to use this with MASON
			System.out.format("%.6f\n", x);
		}*/
		
		double x = Stats.normalToLognormal(mu, sigma, random.nextGaussian());
		System.out.format("%.6f\n", x);
	}
}
