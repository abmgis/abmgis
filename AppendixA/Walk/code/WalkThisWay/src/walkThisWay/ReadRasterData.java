package walkThisWay;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import sim.field.grid.DoubleGrid2D;
import sim.field.grid.IntGrid2D;

//
//*****************************************************************************
// ReadRasterData

public class ReadRasterData {
	public int gridWidth;
	public int gridHeight;
	public double xLowerLeftCorner;
	public double yLowerLeftCorner;
	public double gridSize;
	public int noDataValue;
	public String fileName;

	// This way we can come back to where we left off during reading of the
	// file.
	private BufferedReader d;

	// ***************************************************************************
	/**
	 * WARNING: this is a long method. This is the Read Raster Data class
	 * constructor. It takes the file name of the desired raster data and reads
	 * and stores the meta-data for the specified raster data file.
	 */

	public ReadRasterData(String file) throws IOException {

		fileName = new String(file);

		FileInputStream fstream = null;
		try {
			// Open the file
			fstream = new FileInputStream(fileName);
		} catch (Exception e) {
			System.out.println(e);
		}
		d = new BufferedReader(new InputStreamReader(fstream));

		String s = null;

		// Read in the metadata from the file, this gives the grid width &
		// height
		for (int i = 0; i < 6; i++) {
			s = d.readLine();

			// format the line appropriately
			String[] parts = s.split(" ", 2);
			if (parts.length == 1) {
				parts = s.split("\t", 2);
			}

			String trimmed = parts[1].trim();

			// Code taken from SleuthWorld
			if (i == 1) {
				gridHeight = Integer.parseInt(trimmed);
			} else if (i == 0) {
				gridWidth = Integer.parseInt(trimmed);
			} else if (i == 2) {
				xLowerLeftCorner = Double.parseDouble(trimmed);
			} else if (i == 3) {
				yLowerLeftCorner = Double.parseDouble(trimmed);
			} else if (i == 4) {
				gridSize = Double.parseDouble(trimmed);
			} else if (i == 5) {
				noDataValue = Integer.parseInt(trimmed);
			} else {
				continue;
			}

		}
		// System.out.println(file + " has GridWidth = " + gridWidth +
		// "\nGridHeight = " + gridHeight);

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/**
	 * This method stores the double values of the raster file into DoubleGrid2D
	 * grid.
	 */

	public void readDoubleRaster(DoubleGrid2D grid) throws IOException {

		int i = 0;
		int j = 0;
		String s = null;

		// Basic integrity checks
		if (grid.getWidth() != gridWidth) {
			System.out.println(fileName + " has gridWidth of " + gridWidth
					+ ", grid has gridWidth of " + grid.getWidth());
			return;
		}

		if (grid.getHeight() != gridHeight) {
			System.out.println(fileName + " has gridHeight of " + gridHeight
					+ ", grid has gridHeight of " + grid.getHeight());
			return;
		}

		// System.out.println("Reading in data for " + this.fileName);
		// Read in the rest of the raster file that contains all the data
		while ((s = d.readLine()) != null) {

			String[] parts = s.split(" ");

			for (String p : parts) {
				double num = Double.parseDouble(p);
				grid.set(j, i, num);
				j++;
			}

			// reset the column count
			j = 0;
			// increase the row count
			i++;

		}

		// Close the buffered reader now that data is all read.
		d.close();

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method reads in raster data. */

	public void readIntRaster(IntGrid2D grid) throws IOException {

		int i = 0;
		int j = 0;
		String s = null;

		// Basic integrity checks
		if (grid.getWidth() != gridWidth) {

			System.out.println(fileName + " has gridWidth of " + gridWidth
					+ ", grid has gridWidth of " + grid.getWidth());
			return;

		}

		if (grid.getHeight() != gridHeight) {

			System.out.println(fileName + " has gridHeight of " + gridHeight
					+ ", grid has gridHeight of " + grid.getHeight());
			return;

		}

		// Read in the rest of the raster file that contains all the data
		while ((s = d.readLine()) != null) {

			String[] parts = s.split(" ");

			for (String p : parts) {

				int num = Integer.parseInt(p);

				grid.set(j, i, num);
				j++;

			}

			// reset the column count
			j = 0;
			// increase the row count
			i++;

		}

		// Close the buffered reader now that data is all read.
		d.close();

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the grid width. */

	public int getGridWidth() {

		return gridWidth;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method sets the grid width. */

	public int getGridHeight() {

		return gridHeight;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns lower left x value. */

	public double getxLowerLeftCorner() {

		return xLowerLeftCorner;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns lower left y value. */

	public double getyLowerLeftCorner() {

		return yLowerLeftCorner;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the grid size. */

	public double getGridSize() {

		return gridSize;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns no data value. */

	public int getNoDataValue() {

		return noDataValue;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method does nothing. */

	public void template() {
	}
	// End method.
	// ***************************************************************************

}
