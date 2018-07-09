package walkThisWay;

import java.awt.Color;
import sim.util.*;
import sim.util.gui.ColorMap;

/**
 * Maps numerical levels to colors using either a lookup table, color
 * interpolation, or both. A simple implementation of the ColorMap interface.
 */

// Color interpolation relies on a cache so we don't make billions of colors.
// The slightly slower cache,
// turned on by default, lets us search to a bucket, then wander through the
// bucket to find the right Color.
// The faster cache creates a hard-set Color array. This has lower resolution in
// colors (probably 1/4 the
// true Color values) than the slower cache, but it's faster in lookup by a bit.
// I've commented out the
// faster cache, but you can see how it roughly works.

public class SegmentedColorMap implements ColorMap {
	public final Color clearColor = new Color(0, 0, 0, 0);
	static final int COLOR_DISCRETIZATION = 257;

	double[] levels;
	int[] reds, blues, greens, alphas;

	double maxLevel = 0;
	double minLevel = 0;
	Color minColor = clearColor;
	Color maxColor = clearColor;

	/** User-provided color table */
	public Color[] colors;

	// (The slower cache for color interpolation)
	Bag[] colorCache = new Bag[COLOR_DISCRETIZATION];

	public SegmentedColorMap(double[] levels, Color[] colors) {
		if(levels.length != colors.length)
			System.out.println("hmmm");
		this.colors = colors;
		this.levels = levels;
		
		minColor = colors[0];
		maxColor = colors[colors.length - 1];
		
		minLevel = levels[0];
		maxLevel = levels[levels.length - 1];
		
		int len = colors.length;
		reds = new int[len];
		blues = new int[len];
		greens = new int[len];
		alphas = new int[len];
		for(int i = 0; i < colors.length; i++){
			reds[i] = colors[i].getRed();
			blues[i] = colors[i].getBlue();
			greens[i] = colors[i].getGreen();
			alphas[i] = colors[i].getAlpha();
		}
	}

	public Color[] setColorTable(Color[] colorTable) {
		Color[] retval = colors;
		colors = colorTable;
		return retval;
	}

	public double filterLevel(double level) {
		return level;
	}

	public Color getColor(double level) {

		double minLevel = this.minLevel;
		double maxLevel = this.maxLevel;

		// these next two also handle the possibility that maxLevel = minLevel
		if (level >= maxLevel)
			return maxColor;
		else if (level <= minLevel)
			return minColor;

		int interval = 0;
		for (int i = 1; i < levels.length; i++) { // start at 1, for level <
													// first interval it should
													// be < minLevel
			if (level <= levels[i]) {
				interval = i;
				i = levels.length; // force the for loop to halt
			}
		}
		// reevaluate min,maxLevel for this particular interval
		minLevel = levels[interval - 1];
		maxLevel = levels[interval];
		final double interpolation = (level - minLevel) / (maxLevel - minLevel);

		// the +1's beow are because the only way you can get the maxColor
		// is if you have EXACTLY the maxLevel --
		// that's an incorrect discretization distribution. Instead we
		// return the maxColor if you have the maxLevel,
		// and otherwise we'd like to round it.
		// ... hope that's right! -- Sean

		// look up color in cache
		// (the slower cache)
		// TODO: no longer perfect
		final int alpha = (int) (interpolation * (alphas[interval] - alphas[interval - 1]) + alphas[interval - 1]);
		if (alpha == 0)
			return clearColor;

		final int red = (int) (interpolation * (reds[interval] - reds[interval - 1]) + reds[interval - 1]);
		final int green = (int) (interpolation * (greens[interval] - greens[interval - 1]) + greens[interval - 1]);
		final int blue = (int) (interpolation * (blues[interval] - blues[interval - 1]) + blues[interval - 1]);

		final int rgb = (alpha << 24) | (red << 16) | (green << 8) | blue;
		Color c = new Color(rgb, (alpha != 0));
		return c;

	}

	public int getAlpha(double level) {
		if (colors != null) {
			if (level >= 0 && level < colors.length)
				return colors[(int) level].getAlpha();
		}

		// else...

		final double minLevel = this.minLevel;
		final double maxLevel = this.maxLevel;
		// these next two also handle the possibility that maxLevel = minLevel
		if (level >= maxLevel)
			return maxColor.getAlpha();
		else if (level <= minLevel)
			return minColor.getAlpha();
		else {
			// now convert to between 0 and 1
			double interval = maxLevel - minLevel;
			// finally call the convert() function, then set back to between
			// minLevel and maxLevel
			level = filterLevel((level - minLevel) / interval) * interval
					+ minLevel;
		}

		final double interpolation = (level - minLevel) / (maxLevel - minLevel);

		// TODO all messed up
		final int maxAlpha = alphas[alphas.length - 1];//this.maxAlpha;
		final int minAlpha = alphas[0];//this.minAlpha;
		return (maxAlpha == minAlpha ? minAlpha : (int) (interpolation
				* (maxAlpha - minAlpha) + minAlpha));
	}

	public int getRGB(double level) {

		double minLevel = this.minLevel;
		double maxLevel = this.maxLevel;
		// these next two also handle the possibility that maxLevel = minLevel
		if (level >= maxLevel)
			return maxColor.getRGB();
		else if (level <= minLevel)
			return minColor.getRGB();
		
		int interval = 0;
		for (int i = 1; i < levels.length; i++) { // start at 1, for level <
													// first interval it should
													// be < minLevel
			if (level <= levels[i]) {
				interval = i;
				i = levels.length; // force the for loop to halt
			}
		}
		// reevaluate min,maxLevel for this particular interval
		minLevel = levels[interval - 1];
		maxLevel = levels[interval];
		final double interpolation = (level - minLevel) / (maxLevel - minLevel);

		final int alpha = (int) (interpolation * (alphas[interval] - alphas[interval - 1] ) + alphas[interval - 1]);

		// TODO: not right!
		final int red = (int) (interpolation * (reds[interval] - reds[interval - 1] ) + reds[interval - 1]);
		final int green = (int) (interpolation * (greens[interval] - greens[interval - 1] ) + greens[interval - 1]);
		final int blue = (int) (interpolation * (blues[interval] - blues[interval - 1] ) + blues[interval - 1]);

		return (alpha << 24) | (red << 16) | (green << 8) | blue;
	}

	public boolean validLevel(double value) {
		if (value >= minLevel && value < maxLevel)
			return true;
		return false;
	}

	public double defaultValue() {
		if (colors != null)
			return 0;
		return minLevel;
	}
}
