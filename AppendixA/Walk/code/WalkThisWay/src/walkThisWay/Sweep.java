package walkThisWay;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;

import sim.field.grid.DoubleGrid2D;
import sim.field.grid.IntGrid2D;

public class Sweep {

	
	public static void main(String args[]){

		BufferedWriter myKmls;
		try {
			RasterDoubleGrid2D result = null;
			long numSteps = 0;
			myKmls = new BufferedWriter(new FileWriter("walkThisWay_manyPeds_8Hours.txt"));

			for (int i = 0; i < 30; i++) {
				WalkThisWay walk = new WalkThisWay(System.currentTimeMillis(), false);
				walk.start();
				while (walk.schedule.getTime() < 10 + 60 * 8)
					walk.schedule.step(walk);

				if (result == null) {
					result = walk.traces;
				} else {
					result.add(walk.traces);
				}
				numSteps += walk.totalPedSteps;

				myKmls.write("RUN \t" + i + "\n");
				for (int k = 0; k < result.getWidth(); k++) {
					String myVals = "";
					for (int j = 0; j < result.getHeight(); j++)
						myVals += walk.traces.field[k][j] + "\t";
					myKmls.write(myVals + "\n");
				}
				myKmls.write("\n");
			}

			myKmls.write("FINAL NORAMLISED VALUES FOR " + numSteps + " STEPS\n");
			for (int i = 0; i < result.getWidth(); i++) {
				for (int j = 0; j < result.getHeight(); j++)
					myKmls.write(result.field[i][j] + "\t");
				myKmls.write("\n");
			}

			myKmls.close();
		} catch (IOException e) {
			e.printStackTrace();
		}

		// write a header

		//result.multiply(1. / numSteps); // normalize it
/*		System.out.println(numSteps);
		for(int i = 0; i < result.getWidth(); i++){
			for(int j = 0; j < result.getHeight(); j++)
				System.out.print(result.field[i][j] + ",");
			System.out.println();
		}
*/
	}
	
	static double sumOfAbs(RasterDoubleGrid2D grid1, RasterDoubleGrid2D grid2){
		double result = 0;
		for(int i = 0; i < grid1.getWidth(); i++)
			for(int j = 0; j < grid1.getHeight(); j++){
				if(grid2 == null)
					result += Math.abs(grid1.field[i][j]);
				else
					result += Math.abs(grid1.field[i][j] - grid2.field[i][j]);
			}
		return result;
	}
	
	
/*	public static void main(String args[]) {
				
		String [] maps = {"gradientsAug26wo.txt"},//, null}, 
		entries = {"entExtComboAug26wo.txt"};//, null};
		
		RasterDoubleGrid2D last = null;

		int limit = 30;
		HashMap <Integer, Double> diff = new HashMap <Integer, Double> ();
		for (int i = 10; i <= 1000; i *= 10) {

			RasterDoubleGrid2D result = null;
			long numSteps = 0;

			for (String map : maps) {
				for (String entry : entries) {
					for (int runs = 0; runs < limit; runs++) {

						boolean writeOut = false;
						if (runs == limit - 1)
							writeOut = true;

						WalkThisWay walk = new WalkThisWay( System.currentTimeMillis(), writeOut);
						
						// taking out 8-9am
//						walk.startKeepingRecords = 72000;
//						walk.endKeepingRecords = 108000;
//						
						// taking out 3-4pm
						// 36000 length
						walk.startKeepingRecords = 72000; 
						walk.endKeepingRecords = 108000;
						
						walk.start();
						for (int k = 0; k < 300000; k++) {
							walk.schedule.step(walk);
						}

						if (result == null) {
							result = walk.traces;
						} else {
							result.add(walk.traces);
						}
						numSteps += walk.totalPedSteps;

					}
				}
			}
			
			result.multiply(1. / numSteps); // normalize it
			double val = sumOfAbs(result,last);
			System.out.println(i + " " + val);
			diff.put(i, val);
			last = result;
		}
		
		for(Integer key: diff.keySet()){
			System.out.println(key + "\t" + diff.get(key));
		}
	}

	*/
	void other(){
		
		// process that shiz!!!!
/*
		try {
			
			File directory = new File("/Users/swise/workspace/Crooks/walkThisWayData/pedTraces/sweepdata/TT");
			String [] filenames = directory.list();
			ArrayList <IntGrid2D> grids = new ArrayList <IntGrid2D> ();
			ArrayList <Integer> gridSizes = new ArrayList <Integer> ();
			
			for(String file: filenames){
				// Open the file
				FileInputStream fstream = new FileInputStream(directory + "/" + file);

				// Convert our input stream to a BufferedReader
				BufferedReader d = new BufferedReader(new InputStreamReader(fstream));

				
				// copy over the data
				int width = Integer.parseInt((d.readLine()).split(" ")[9]);
				int height = Integer.parseInt((d.readLine()).split(" ")[9]);

				IntGrid2D grid = new IntGrid2D(width, height);

				for(int i = 0; i < 4; i++)
					d.readLine(); // get rid of that shiz!

				String s;
				int sum = 0;
				int index = 0;
				while ((s = d.readLine()) != null) {
					String[] bits = s.split(" ");
					int len = bits.length;
					for (int i = 0; i < len; i++) {
						int num = Integer.parseInt(bits[i]);
						grid.field[i][index] = num;
						sum += num;
					}
					index++;
				}

				// clean up
				d.close();
				
				grids.add(grid);
				gridSizes.add(sum);
			}
			
			DoubleGrid2D masterGrid = new DoubleGrid2D(grids.get(0).getWidth(), grids.get(0).getHeight());
			for(int i = 0; i < grids.size(); i++){
				IntGrid2D thisgrid = grids.get(i);
				int size = gridSizes.get(i);
				
				DoubleGrid2D newgrid = new DoubleGrid2D(thisgrid.getWidth(), thisgrid.getHeight());
				for(int x = 0; x < thisgrid.getWidth(); x++)
					for(int y = 0; y < thisgrid.getHeight(); y++)
						newgrid.field[x][y] = ((double)thisgrid.field[x][y]) / ((double)size);

				masterGrid.add(newgrid);
			}
			
			for(int x = 0; x < masterGrid.getWidth(); x++){
				for(int y = 0; y < masterGrid.getHeight(); y++){
					System.out.print(masterGrid.field[x][y] + "\t");
				}
				System.out.println();
			}
			
		} catch (Exception e) {
			System.err.println("File input error");
		}
		*/
	}
	
}