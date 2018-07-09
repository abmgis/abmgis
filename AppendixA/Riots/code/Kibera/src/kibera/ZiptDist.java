/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package kibera;

/**
 *
 * @author http://diveintodata.org/2009/09/13/zipf-distribution-generator-in-java/
 * I am using it for generating income and livestock holding
 */
import ec.util.MersenneTwisterFast;
import java.lang.Math;
public class ZiptDist {

    private MersenneTwisterFast rnd = new MersenneTwisterFast(System.currentTimeMillis());
    private int size;
    private double skew;
    private double bottom = 0;

    public ZiptDist(int size, double skew) {
        this.size = size;
        this.skew = skew;

        for (int i = 1; i < size; i++) {
            this.bottom += (1 / Math.pow(i, this.skew));
        }
    }
    // the next() method returns an random rank id.
    // The frequency of returned rank ids are follows Zipf distribution.

    public int next() {
        int rank;
        double friquency = 1;
        double dice;

        rank = rnd.nextInt(size);
        friquency = (1.0d / Math.pow(rank, this.skew)) / this.bottom;
        dice = rnd.nextDouble();

        while (!(dice < friquency)) {
            rank = rnd.nextInt(size);
            friquency = (1.0d / Math.pow(rank, this.skew)) / this.bottom;
            dice = rnd.nextDouble();
        }
        return rank;

    }
    // This method returns a probability that the given rank occurs.

    public double getProbability(int rank) {
        return (1.0d / Math.pow(rank, this.skew)) / this.bottom;
    }

   
}
