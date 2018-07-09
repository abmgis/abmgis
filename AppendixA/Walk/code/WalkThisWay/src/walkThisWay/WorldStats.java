package walkThisWay;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;

import java.util.ArrayList;

import sim.field.grid.IntGrid2D;
import sim.field.grid.ObjectGrid2D;
import sim.util.Heap;
import sim.util.Int2D;
import sim.util.Int3D;
import sim.util.IntBag;

public class WorldStats {


	IntGrid2D entrances, exits, obstacles;
	int numEntrances, numExits;
	public ArrayList<ArrayList<Int2D>> entrancePoints;
	public ArrayList<ArrayList<Int2D>> exitPoints;
	ArrayList<ArrayList<Int3D>> paths;
	int [] entranceConnectivity;
	int [][] exitConnectivity;
	
	ArrayList <Int2D> pairings;
	ArrayList <IntGrid2D> heatmaps;
	IntGrid2D masterHeatmap;
	ArrayList <String> pathInfo;
	
	double entryInstances;
	
	public int startGap = -1, endGap = -1;
	
	int startKeepingRecords = 72000, endKeepingRecords = 108000;

	
	public IntGrid2D readIntoGrid(String filename)
			throws NumberFormatException, IOException {

		IntGrid2D result = null;

		try {
			FileInputStream fstream = new FileInputStream(filename);

			// Convert our input stream to a BufferedReader
			BufferedReader d = new BufferedReader(
					new InputStreamReader(fstream));

			String s;

			int width = Integer.parseInt(d.readLine());
			int height = Integer.parseInt(d.readLine());

			result = new IntGrid2D(width, height);

			int j = 0;
			while ((s = d.readLine()) != null) {
				String[] bits = s.split("\t");
				for (int i = 0; i < bits.length; i++) {
					int num = Integer.parseInt(bits[i]);
					result.field[i][j] = num;
				}
				j++;
			}

			d.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return result;
	}

	public ArrayList<ArrayList<Int3D>> readPaths(String filename)
			throws NumberFormatException, IOException {

		ArrayList<ArrayList<Int3D>> paths = new ArrayList<ArrayList<Int3D>>();

		try {
			FileInputStream fstream = new FileInputStream(filename);

			// Convert our input stream to a BufferedReader
			BufferedReader d = new BufferedReader(
					new InputStreamReader(fstream));

			String s;

			while ((s = d.readLine()) != null) {
				String[] bits = s.split("\t");
				ArrayList<Int3D> path = new ArrayList<Int3D>();
				for (int i = 0; i < bits.length; i += 3) {
					Int3D point = new Int3D(Integer.parseInt(bits[i]),
							Integer.parseInt(bits[i + 1]),
							Integer.parseInt(bits[i + 2]));
					
					if(point.z > startGap && point.z < endGap)
						continue; // within the omitted time period!!!
					
					path.add(point);
				}
				if(path.size() > 0)
					paths.add(path);
			}

			d.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}

		return paths;
	}

	public int[][] processPaths() {
		int[][] result = new int[numEntrances][numExits];
		entranceConnectivity = new int[numEntrances];
		pathInfo = new ArrayList <String> ();

		ObjectGrid2D pathsExitEntranceCombos = new ObjectGrid2D(numEntrances, numExits);
		for(int i = 0; i < numEntrances; i++){
			for(int j = 0; j < numExits; j++){
				pathsExitEntranceCombos.set(i,j, new ArrayList <ArrayList<Int3D>>());
			}
		}

		entryInstances = 0;
		for (ArrayList<Int3D> path : paths) {
			Int3D start = path.get(0), end = path.get(path.size() - 1);
			int startIndex = entrances.field[start.x - 1][start.y - 1] - 1, 
				endIndex = exits.field[end.x - 1][end.y - 1] - 1;
			
			if(startIndex >= 0 && startIndex < numEntrances && endIndex >= 0 && endIndex < numExits){
				entryInstances++;
				entranceConnectivity[startIndex]++;
				result[startIndex][endIndex]++;
				((ArrayList)pathsExitEntranceCombos.get(startIndex, endIndex)).add(path);
				pathInfo.add( new String(startIndex + "\t" + endIndex + "\t" + start.z) );
			}
			else
				System.out.println(start.x + ", " + start.y + ":" + startIndex + "\t" + end.x + ", " + end.y + ":" + endIndex);
		}
		
		pairings = new ArrayList <Int2D> ();
		heatmaps = new ArrayList <IntGrid2D> ();
		masterHeatmap = new IntGrid2D(entrances.getWidth(), entrances.getHeight());
		
		for(int i = 0; i < numEntrances; i++){
			for(int j = 0; j < numExits; j++){
				ArrayList <ArrayList <Int3D>> myPaths = (ArrayList <ArrayList <Int3D>>) pathsExitEntranceCombos.get(i,j);
				if(myPaths.size() == 0) continue;
				IntGrid2D myHeatmap = new IntGrid2D(entrances.getWidth(), entrances.getHeight());
				for(ArrayList <Int3D> path: myPaths){
					//Int3D lastPoint = null;
					for(Int3D point: path){
						//if(point.equals(lastPoint)) continue; // only count use of tile once
						if(point.x > 0 && point.x < myHeatmap.getWidth() && point.y > 0 && point.y < myHeatmap.getHeight()){
							myHeatmap.field[point.x][point.y]++;
							if(point.z >= startKeepingRecords && point.z <= endKeepingRecords)
								masterHeatmap.field[point.x][point.y]++;
						}
						//lastPoint = point;
					}
				}
				pairings.add(new Int2D(i,j));
				heatmaps.add(myHeatmap);
			}
		}
		
		return result;
	}

	
	public class GradientPoint{
		int x, y;
		int height;
		int mycost;

		public GradientPoint(int i, int j){
			this(i,j,1);
		}
		public GradientPoint(int i, int j, int cost){
			x = i; y = j;
			height = Integer.MAX_VALUE;
			mycost = cost;
		}
	}
	
	public ObjectGrid2D constructGradients(){
		
		ObjectGrid2D entranceExitGradients = new ObjectGrid2D(numEntrances, numExits);
		int noval = -9999;
		
		//
		// for each entrance/exit pair, calculate a gradient
		//
		for(int i = 0; i < numEntrances; i++){
			for(int j = 0; j < numExits; j++){
				
				
				// if we have heatmap information from the data, pull it up here. Otherwise assume no pattern
				IntGrid2D myHeatmap = null;
				int indexOfMyHeatmap = pairings.indexOf(new Int2D(i,j));
				if(indexOfMyHeatmap >= 0)
					myHeatmap = heatmaps.get(indexOfMyHeatmap);
				else
					myHeatmap = new IntGrid2D(entrances.getWidth(), entrances.getHeight());
				
				ArrayList <GradientPoint> open = new ArrayList <GradientPoint> (), 
					done = new ArrayList <GradientPoint> ();
				
				//ArrayList <Int2D> done = new ArrayList <Int2D> ();

				Heap heapity = new Heap();

				int hottest = 2;
				// create an ObjectGrid2D to hold all of these GradientPoints
				ObjectGrid2D gradient = new ObjectGrid2D(entrances.getWidth(), entrances.getHeight());
				for(int x = 0; x < gradient.getWidth(); x++){
					for(int y = 0; y < gradient.getHeight(); y++){
						int heat = myHeatmap.field[x][y];
						GradientPoint g = new GradientPoint(x,y, Math.max(heat, 1));
						gradient.set(x, y, g);
						
						if(heat + 1 > hottest) hottest = heat + 1;
					}
				}
				
				// the exit points, by definition, have distance 0 from the exit: look around them and see
				for(Int2D point: exitPoints.get(j)){
					GradientPoint g = ((GradientPoint) gradient.get(point.x, point.y));
					g.height = 0;
					open.add(g);
//					gradientOut.field[point.x][point.y] = 0;
//					heapity.add(new Int2D(point.x, point.y), 0);
				}
				
				
				
				while( open.size() > 0 ){
//					Int2D g = (Int2D) heapity.extractMin();
					GradientPoint g = minDist(open);
					open.remove(g);
					done.add(g);

					// otherwise, check out all of the places to which this connects
					for(Object o: gradient.getNeighborsHamiltonianDistance(g.x, g.y, 1, false, null, null, null)){
					/*IntBag xs = null, ys = null;
					gradientOut.getNeighborsHamiltonianDistance(g.x, g.y, 1, false, xs, ys);
					for(int k = 0; k < xs.size(); k++){
						int height = gradientOut.field[xs.get(k)][ys.get(k)];
						
						Int2D neighbor = new Int2D(xs.get(k), ys.get(k));

//						if(o == null) // we've previously found this, and it's an obstacle. Do not consider it.
//							continue;
						if(height < 0) // we've previously found this, and it's an obstacle. Do not consider it.
							continue; 
*/
						GradientPoint openPoint = (GradientPoint) o;

						if(done.contains(openPoint))
							continue;
						// if something is an obstacle, it has no connectivity with its partners
						else if(obstacles.get(openPoint.x, openPoint.y) > 0){
							//gradientOut.field[g.x][g.y] = -1;
							//gradient.set(g.x, g.y, -1);
							openPoint.height = -1;
							done.add(openPoint);
							continue;
						}

						int tentativeDist = g.height + 
							1; // NO HEAT
							//(hottest - neighbor.mycost);// HEAT
						/*if(myHeatmap != null)
							tentativeDist += myHeatmap.field[neighbor.x][neighbor.y];
						else
							tentativeDist++;
*/
						
						if(! open.contains(openPoint)){
							openPoint.height = tentativeDist;
							open.add(openPoint);
						}
						else if(tentativeDist < openPoint.height)
							openPoint.height = tentativeDist;

					}
				}

				
				
				IntGrid2D gradientOut = new IntGrid2D(entrances.getWidth(), entrances.getHeight());


				for(int x = 0; x < gradient.getWidth(); x++){
					for(int y = 0; y < gradient.getHeight(); y++){
						Object o = gradient.get(x,y);
						int obstacle = obstacles.get(x, y);
						if(obstacle > 0)
							gradientOut.field[x][y] = noval;
						else
							gradientOut.field[x][y] = ((GradientPoint)gradient.get(x, y)).height;
					}
				}

				entranceExitGradients.set(i, j, gradientOut);
			}
		}
		return entranceExitGradients;
	}
	
	GradientPoint minDist(ArrayList <GradientPoint> ps){
		int min = Integer.MAX_VALUE;
		GradientPoint result = null;
		for(GradientPoint p: ps){
			if(p.height < min){ // need to tie-break -- if there are many with the same score, take the first added
				min = p.height;
				result = p;
			}
		}
		return result;
	}
	
	void start() {
		Long time = System.currentTimeMillis();
		String finEnt = "walkThisWayData/EntranceUNIQUE.txt", 
			finExt = "walkThisWayData/ExitUNIQUE.txt", 
			finPath = "walkThisWayData/Aug26allTABS.txt",
			finObs = "walkThisWayData/obstacles.txt",
			
			fout = "walkThisWayData/results" + time + ".txt",
			foutMaps = "walkThisWayData/resultsMaps" + time + ".txt",
			fPathInfo = "walkThisWayData/resultsPathInfo" + time + ".txt";

		try {

			String s;

			entrancePoints = new ArrayList <ArrayList <Int2D>> ();
			entrances = readIntoGrid(finEnt);
			for(int i = 0; i < entrances.getWidth(); i++)
				for(int j = 0; j < entrances.getHeight(); j++){
					if(entrances.field[i][j] > 0){
						// add points
						for(int x = entrances.field[i][j] - numEntrances; x > 0; x--)
							entrancePoints.add(new ArrayList <Int2D> ());
						entrancePoints.get(entrances.field[i][j]-1).add(new Int2D(i,j));
					}
					
					if(entrances.field[i][j] > numEntrances){
						numEntrances = entrances.field[i][j];
					}

				}

			exitPoints = new ArrayList <ArrayList <Int2D>> ();
			exits = readIntoGrid(finExt);
			for(int i = 0; i < exits.getWidth(); i++)
				for(int j = 0; j < exits.getHeight(); j++){
					if(exits.field[i][j] > 0){
						// add points
						for(int x = exits.field[i][j] - numExits; x > 0; x--)
							exitPoints.add(new ArrayList <Int2D> ());
						exitPoints.get(exits.field[i][j]-1).add(new Int2D(i,j));
					}

					if(exits.field[i][j] > numExits){
						numExits = exits.field[i][j];
					}
				}

			obstacles = readIntoGrid(finObs);
			
			paths = readPaths(finPath);
			exitConnectivity = processPaths();
			
			System.out.println("Begin Master Heatmap");
			for(int i = 0; i < entrances.getWidth(); i++){
				for(int j = 0; j < entrances.getHeight(); j++){
					System.out.print(masterHeatmap.field[i][j] + "\t");
				}
				System.out.println();
			}
			System.out.println("End Master Heatmap");
			
			
			ObjectGrid2D gradients = constructGradients();
			
	//		System.out.println("\nRESULTS\n");
			
			BufferedWriter w = new BufferedWriter(new FileWriter(fout));
			w.write(numEntrances + "\n" + numExits + "\n");

			for(int i = 0; i < numEntrances; i++){
				w.write(entranceConnectivity[i]/entryInstances + "\n");
				if(entranceConnectivity[i] == 0) entranceConnectivity[i] = 1;
			}
			for(int i = 0; i < numEntrances; i++){
				for(int j = 0; j < numExits; j++){
//					System.out.print(exitConnectivity[i][j] + "\t");
					w.write((exitConnectivity[i][j]/(double)entranceConnectivity[i]) + "\t");
				}
				w.newLine();
//				System.out.println();
			}

			// clean up
			w.close();
			
			BufferedWriter bw = new BufferedWriter(new FileWriter(foutMaps));
			/*
			bw.write(entrances.getWidth() + "\n" + entrances.getHeight());
			for(int i = 0; i < pairings.size(); i++){
				bw.newLine();
				Int2D point = pairings.get(i);
				IntGrid2D map = heatmaps.get(i);
				
				bw.write(point.x + "\t" + point.y + "\n");
				for(int j = 0; j < map.getWidth(); j++){
					for(int k = 0; k < map.getHeight(); k++)
						bw.write(map.field[j][k] + "\t");
					bw.newLine();
				}
			}
			*/
			
			bw.write(numEntrances + "\n" + numExits + "\n" + exits.getWidth() + "\n" + exits.getHeight() + "\n");

			// for each entrance/exit pair, calculate a gradient
			for(int i = 0; i < numEntrances; i++){
				for(int j = 0; j < numExits; j++){
					IntGrid2D map = (IntGrid2D) gradients.field[i][j];
					bw.newLine();
					bw.write(i + "\t" + j + "\n");
					// for each entrance/exit pair, calculate a gradient
					for(int x = 0; x < map.getWidth(); x++){
						for(int y = 0; y < map.getHeight(); y++){
							bw.write(map.field[x][y] + "\t");
						}
						bw.newLine();						
					}

				}
			}

			// clean up
			bw.close();
			
			BufferedWriter ps = new BufferedWriter(new FileWriter(fPathInfo));
			for(String str: pathInfo){
				ps.write(str + "\n");
			}
			ps.close();

			
		} catch (Exception e) {
			System.err.println("File input error");
		}
	}

	public static void main(String[] args) {

		WorldStats stats = new WorldStats();
		stats.start();
	}
}