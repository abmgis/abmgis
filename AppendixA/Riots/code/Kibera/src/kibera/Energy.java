package kibera;

public class Energy {
	
	public static double calculateAggression(double currentEnergy, double aggressionRate, Resident me, Kibera kibera) {
            /**
             * This function uses the logistic function to calculate resident's energy level as they seek to meet their
             * identity standard.
             */
		
            double xMin = 0;
            double xMax = 100;
            double rate = aggressionRate;

            int householdHappiness = me.getHousehold().householdHappiness(kibera);

            if (householdHappiness == 1) {
                    rate = rate * (1/3) + rate;
            }
            if (householdHappiness == 2) {
                    rate = rate * (2/3) + rate;
            }

            double exp = 0.0;
            double aggressValue = 0.0;

            exp = 20 / (xMax - xMin + 1) * (currentEnergy - ((xMax - xMin) / 2 + xMin));
            aggressValue = 1 / (1 + Math.exp(-1 * rate * exp));	

            //check if aggress value is less than aggress threshold
            //if aggress value is less, the resident becomes aggressive		
            return aggressValue;
	}
	
}
