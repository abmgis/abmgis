/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */
import ec.util.Parameter;
import ec.util.ParameterDatabase;
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;

public class Parameters {
    
      GlobalParamters global = new GlobalParamters();
  
    private final static String A_FILE = "-file";

    public Parameters(String[] args) {
        if (args != null) {
            loadParameters(openParameterDatabase(args));
        }
    }

    //<editor-fold defaultstate="collapsed" desc="ECJ ParameterDatabase methods">
    /**
     * Initialize parameter database from file
     *
     * If there exists an command line argument '-file', create a parameter
     * database from the file specified. Otherwise create an empty parameter
     * database.
     *
     * @param args contains command line arguments
     * @return newly created parameter data base
     *
     * @see loadParameters()
     */
    private static ParameterDatabase openParameterDatabase(String[] args) {
        ParameterDatabase parameters = null;
        for (int x = 0; x < args.length - 1; x++) {
            if (args[x].equals(A_FILE)) {
                try {
                    File parameterDatabaseFile = new File(args[x + 1]);
                    parameters = new ParameterDatabase(parameterDatabaseFile.getAbsoluteFile());
                } catch (IOException ex) {
                    ex.printStackTrace();
                }
                break;
            }
        }
        if (parameters == null) {
            System.out.println("\nNot in a parameter Mode");//("\nNo parameter file was specified");
            parameters = new ParameterDatabase();
        }
        return parameters;
    }

    private void loadParameters(ParameterDatabase parameterDB) {
//        
        // global - enterprise
//        global.SetInitialNumberOfHouseholds(returnIntParameter(parameterDB, "InitialNumberOfHouseholds",
//                 global.getInitialNumberOfHouseholds()));
//        
        global.setInitialRefugeeNumber(returnIntParameter(parameterDB, "initialRefugeeNumber",
                 global.getInitialRefugeeNumber()));
        global.setMaximumNumberRelative(returnIntParameter(parameterDB, "MaximumNumberRelative",
                 global.getMaximumNumberRelative()));
        global.setPercentageOfAsymptomatic(returnDoubleParameter(parameterDB, "PercentageOfAsymptomatic",
                 global.getPercentageOfAsymptomatic()));
        global.setProbRecoveryToSuscebtable(returnDoubleParameter(parameterDB, "recovery_To_Susceb_Rate",
                 global.getProbRecoveryToSuscebtable()));
        global.setHealthDepreciation(returnDoubleParameter(parameterDB, "healthDepreciation",
                 global.getHealthDepreciation()));
        global.setprobabilityOfEffectiveNessofmedicine(returnDoubleParameter(parameterDB, "probabilityOfEffectiveNessofmedicine",
                 global.getprobabilityOfEffectiveNessofmedicine()));
        global.setWaterContaminationThreshold(returnDoubleParameter(parameterDB, "WaterContaminationThreshold",
                 global.getWaterContaminationThreshold()));
        global.setvibrioCholeraePerHealthyPerson(returnDoubleParameter(parameterDB, "vibrioCholeraePerHealthyPerson",
                 global.getvibrioCholeraePerHealthyPerson()));
        global.setvibrioCholeraePerExposedPerson(returnDoubleParameter(parameterDB, "vibrioCholeraePerExposedPerson",
                 global.getvibrioCholeraePerExposedPerson()));
        global.setvibrioCholeraePerInfectedPerson(returnDoubleParameter(parameterDB, "vibrioCholeraePerInfectedPerson",
                 global.getvibrioCholeraePerInfectedPerson()));
         global.setcholeraInfectionDurationMAX(returnIntParameter(parameterDB, "choleraInfectionDurationMAX",
                 global.getcholeraInfectionDurationMAX()));
          global.setcholeraInfectionDurationMIN(returnIntParameter(parameterDB, "choleraInfectionDurationMIN",
                 global.getcholeraInfectionDurationMIN()));       
        global.setMaxDistanceLaterine(returnIntParameter(parameterDB, "MaxDistanceLaterine",
                 global.getMaxDistanceLaterine()));
        global.setBacteriaErosionRate(returnDoubleParameter(parameterDB, "bacteriaErosionRate",
                 global.getBacteriaErosionRate()));
        global.setBoreHoleDischareRatePerMinute(returnDoubleParameter(parameterDB, "boreHoleDischareRate",
                 global.getBoreHoleDischareRatePerMinute()));
        global.setBoreholeWaterSupplyPerDay(returnDoubleParameter(parameterDB, "waterCapacityBorehole",
                 global.getBoreholeWaterSupplyPerDay()));
        global.setHeaalthFacilityCapacity(returnIntParameter(parameterDB, "healthFacilityCapacity",
                 global.getHeaalthFacilityCapacity()));
        global.setMaximumCrowedLevel(returnDoubleParameter(parameterDB, "CROWED_LEVEL_THRESHOLD",
                 global.getMaximumCrowedLevel()));
        global.setProbabilityGuestContaminationRate(returnDoubleParameter(parameterDB, "probabilityGuestContaminationRate",
                 global.getProbabilityGuestContaminationRate()));
        global.setMaximumHHOccumpancyPerField(returnIntParameter(parameterDB, "maximum_occupancy_Threshold",
                 global.getMaximumHHOccumpancyPerField()));
        global.setMaximumWaterRequirement(returnDoubleParameter(parameterDB, "Maximum_Water_Requirement",
                 global.getMaximumWaterRequirement()));
        global.setMinimumWaterRequirement(returnDoubleParameter(parameterDB, "Minimum_Water_Requirement",
                 global.getMinimumWaterRequirement()));
        global.setLaterineCoverage(returnDoubleParameter(parameterDB, "laterineCoverage",
                 global.getLaterineCoverage()));
        global.setRainfallDuration_Minute(returnIntParameter(parameterDB, "rainDuration",
                 global.getRainfallDuration_Minute()));
        global.setRainfallFirstDay(returnIntParameter(parameterDB, "firstRainfallDay",
                 global.getRainfallFirstDay()));
        global.setRainfallFrequencyInterval_Days(returnIntParameter(parameterDB, "rainfallFrequency",
                 global.getRainfallFrequencyInterval_Days()));
        global.setRainfall_MM_Per_Minute(returnDoubleParameter(parameterDB, "rainfallInMM",
                 global.getRainfall_MM_Per_Minute()));
        global.setAbsorbtionRatePerMinute(returnDoubleParameter(parameterDB, "absorbtionRatePerMinute",
                 global.getAbsorbtionRatePerMinute()));
       
        
        
    }

    public int returnIntParameter(ParameterDatabase paramDB, String parameterName, int defaultValue) {
        return paramDB.getIntWithDefault(new Parameter(parameterName), null, defaultValue);
    }

    public boolean returnBooleanParameter(ParameterDatabase paramDB, String parameterName, boolean defaultValue) {
        return paramDB.getBoolean(new Parameter(parameterName), null, defaultValue);
    }

    double returnDoubleParameter(ParameterDatabase paramDB, String parameterName, double defaultValue) {
        return paramDB.getDoubleWithDefault(new Parameter(parameterName), null, defaultValue);
    }

    public class GlobalParamters {
      

        public int initialRefugeeNumber = 4000;// min-1000
        public double PercentageOfAsymptomatic = 70; // how many of the total refugee are asymtototic
        public double recovery_To_Susceb_Rate = 0.000001; // prob of change from recovered  to suscebtible 
        public int MaxDistanceLaterine = 20;
        public int maximum_occupancy_Threshold = 1000; // arbitrary
        public double Maximum_Water_Requirement = 15; // 15 liter per day -  for all uses
        public double Minimum_Water_Requirement = 2;
        public int MaximumNumberRelative = 15;
        public double CROWED_LEVEL_THRESHOLD = 4000;  // 50% of the cellsize 90*90=8100
        public double probabilityOfEffectiveNessofmedicine = 0.9; //90% of the time
        public double WaterContaminationThreshold = 10000.0; // --1000/ml http://www.medicalecology.org/water/cholera/cholera.htm
        public double bacteriaErosionRate = 0.8; // how much of the bacteria in feces are taken up by water
        public double vibrioCholeraePerHealthyPerson = 100.0; // should be very much less than treshold
        public double vibrioCholeraePerExposedPerson = 100000.0; // should be very much less than treshold
        public double vibrioCholeraePerInfectedPerson = 1000000000.0; // person with cholera exert 1000,000,000 virus/ml  franco.et al 1997 
        public int choleraInfectionDurationMIN = 12;  // 12 to 72 hours after ingestion   Nichlas et. al 2009Cholera transmission: the host, pathogen and bacteriophage dynamic
        public int choleraInfectionDurationMAX = 72; // 72 hours after ingestion 
        public double healthDepreciation = 0.001; // agent will die if not get medication in 48 hours ( assumption) - childer will die fast
        public double waterCapacityBorehole = 20; // litre/day/person
        public double boreHoleDischareRate = 0.8;  // litre/minute // proportion of total water capacity
        public double probabilityGuestContaminationRate = 0.005;// assumption - guest who is infected may contaminte host house- vomite discharge
        public double waterSourcePreferenceBorehole = 0.75;
        public double waterSourcePreferenceRiver = 0.25;
        public double waterCoverageRate = 0.7; // % water coverage 
        public int healthFacilityCapacity = 1000; // 500 person/day efficient to treat cholera victim
        public double laterineCoverage = 0.6; //% of clean laterine coverage
        public double rainfallInMM = 4.5;  // assume 75mm/month -  duration = 25 minute, amount = 0.5mm/minute, freq = every 5days (6days in a month)
        public int rainDuration = 25; // minute // 
        public int firstRainfallDay = 0; // the first onset of rainfall
        public int rainfallFrequency = 25;  // rain will fall in days interval
        public double absorbtionRatePerMinute = 4.33;// mm/minute evaporation  - taking median 1750 = 
        
        
        //annual evapration is much higher than the rainfall amount
        // annual rainfall 400-700mm/year
        // evaporation 1500-2000 mm/year
        // mm/minute rainfall evaporate or lost due to seepage
       /*
     * monthly rainfall of Dadaab area. Girissa is the adminstrative destrict
     * where dadaab is located the data is on monthly bases As the model is
     * extent is small and no inflow of waer from upstream, it is necessary to
     * increase the amount of rain to certain extent to accomulate sufficient
     * water so that agent can fetch from their surrounding
     *
     * Rainfall modeling considers rainfall-intensity-frequency-duration (IDF)
     * intensity = amount of rainfall frequency - gaps between days - rain can
     * be happening every day or once in a week ... duration- how many minute
     * the rain stays Paaijmans et. al. 2007 documented rainfall duration and
     * intensity in their anopheles fgambiae study this study can be used as
     * proxy for etimating duration rainfall "The total quantity of rainfall
     * varied from 0.2 to 39.8 mm per night and the maximum rainfall intensity
     * recorded was 9.5 mm in 5 minutes"
     */
    // http://www.weather-and-climate.com/average-monthly-precipitation-Rainfall,Garissa,Kenya
    // {jan-15,10,25,60,17,7,2,10,7,21,78,62-Dec}
    // worlbank at dadaab average rainfall 1990-2009
        //http://sdwebx.worldbank.org/climateportal/index.cfm?page=country_historical_climate&ThisRegion=Africa&ThisCCode=KEN
        
        // {jan-4,3,34,70,61,28,17,7,12,35,85,31-Dec}
    // can range 40 mm / day rain in kenya
    // // annual rainfall 400-700mm/year
    // evaporation 1500-2000 mm/year
    // mm/minute rainfall evaporate or lost due to seepage
    // for simplification, and easy search , it is good to hold in bags

        public void setInitialRefugeeNumber(int num) {
            this.initialRefugeeNumber = num;
        }

        public int getInitialRefugeeNumber() {
            return initialRefugeeNumber;

        }
        
        public void setMaximumNumberRelative(int num) {
            this.MaximumNumberRelative = num;
        }

        public int getMaximumNumberRelative() {
            return MaximumNumberRelative;

        }
        // percentage of asymtotic agent

        public void setPercentageOfAsymptomatic(double a) {
            this.PercentageOfAsymptomatic = a;
        }

        public double getPercentageOfAsymptomatic() {
            return PercentageOfAsymptomatic;
        }

        // probability of recovered agent to be suscebtable again
        public void setProbRecoveryToSuscebtable(double rec) {
            this.recovery_To_Susceb_Rate = rec;
        }

        public double getProbRecoveryToSuscebtable() {
            return recovery_To_Susceb_Rate;
        }

        public void setBacteriaErosionRate(double er) {
            this.bacteriaErosionRate = er;
        }

        public double getBacteriaErosionRate() {
            return bacteriaErosionRate;
        }
        
        public void setHealthDepreciation(double er) {
            this.healthDepreciation = er;
        }

        public double getHealthDepreciation() {
            return healthDepreciation;
        }
        public void setvibrioCholeraePerHealthyPerson(double er) {
            this.vibrioCholeraePerHealthyPerson = er;
        }

        public double getvibrioCholeraePerHealthyPerson() {
            return vibrioCholeraePerHealthyPerson;
        }
        public void setvibrioCholeraePerExposedPerson(double er) {
            this.vibrioCholeraePerExposedPerson = er;
        }

        public double getvibrioCholeraePerExposedPerson() {
            return vibrioCholeraePerExposedPerson;
        }
        public void setvibrioCholeraePerInfectedPerson(double er) {
            this.vibrioCholeraePerInfectedPerson = er;
        }

        public double getvibrioCholeraePerInfectedPerson() {
            return vibrioCholeraePerInfectedPerson;
        }
        public void setcholeraInfectionDurationMAX(int er) {
            this.choleraInfectionDurationMAX = er;
        }

        public int getcholeraInfectionDurationMAX() {
            return choleraInfectionDurationMAX;
        }
        
        public void setcholeraInfectionDurationMIN(int er) {
            this.choleraInfectionDurationMIN= er;
        }

        public int getcholeraInfectionDurationMIN() {
            return choleraInfectionDurationMIN;
        }
        public void setWaterContaminationThreshold(double er) {
            this.WaterContaminationThreshold = er;
        }

        public double getWaterContaminationThreshold() {
            return WaterContaminationThreshold;
        }
        
         public void setprobabilityOfEffectiveNessofmedicine(double er) {
            this.probabilityOfEffectiveNessofmedicine = er;
        }

        public double getprobabilityOfEffectiveNessofmedicine() {
            return probabilityOfEffectiveNessofmedicine;
        }
        // determien the number of agent per field or parcel
        

        public void setMaximumHHOccumpancyPerField(int num) {
            this.maximum_occupancy_Threshold = num;
        }

        public int getMaximumHHOccumpancyPerField() {
            return maximum_occupancy_Threshold;

        }

        // determine the maximum water requirement of agent per day
        public void setMaximumWaterRequirement(double w) {
            this.Maximum_Water_Requirement = w;
        }

        public double getMaximumWaterRequirement() {
            return Maximum_Water_Requirement;
        }
        
        public void setProbabilityGuestContaminationRate(double w) {
            this.probabilityGuestContaminationRate = w;
        }

        public double getProbabilityGuestContaminationRate() {
            return probabilityGuestContaminationRate;
        }

        // determine the minimum water requirement of agent per day
        public void setMinimumWaterRequirement(double w) {
            this.Minimum_Water_Requirement = w;
        }

        public double getMinimumWaterRequirement() {
            return Minimum_Water_Requirement;
        }
        
        public void setLaterineCoverage(double w) {
            this.laterineCoverage = w;
        }

        public double getLaterineCoverage() {
            return laterineCoverage;
        }
        
        public void setMaxDistanceLaterine(int w) {
            this.MaxDistanceLaterine = w;
        }

        public int getMaxDistanceLaterine() {
            return MaxDistanceLaterine;
        }

        // determine how many agent can be stay in a given field or road at the same time
        public void setMaximumCrowedLevel(double c) {
            this.CROWED_LEVEL_THRESHOLD = c;
        }

        public double getMaximumCrowedLevel() {
            return CROWED_LEVEL_THRESHOLD;
        }

        // determine water holding capacity of each borehole (per day)
        public void setBoreholeWaterSupplyPerDay(double w) {

            this.waterCapacityBorehole = w;
        }

        public double getBoreholeWaterSupplyPerDay() {
            return (waterCoverageRate * waterCapacityBorehole * this.getInitialRefugeeNumber()) / 20.0;   // 20 boreholes each 
        }

        // refill rate of each borehole
        public void setBoreHoleDischareRatePerMinute(double w) {
            this.boreHoleDischareRate = w;
        }

        public double getBoreHoleDischareRatePerMinute() {
            return boreHoleDischareRate * (waterCoverageRate * waterCapacityBorehole * this.getInitialRefugeeNumber()) / (1440 *20.0);   // 20 boreholes each / 1440 minute 
        }

        // rainfall 
        public void setRainfall_MM_Per_Minute(double r) {
            this.rainfallInMM = r;
        }

        public double getRainfall_MM_Per_Minute() {
            return rainfallInMM;
        }

        // seepage indicate amount of water loss from the environment
        // can be as evapotranspiration or seepage
        public void setAbsorbtionRatePerMinute(double r) {
            this.absorbtionRatePerMinute = r;
        }

        public double getAbsorbtionRatePerMinute() {
            return absorbtionRatePerMinute;
        }

        /*
         * water preference of agent
         * there are two sources - borehole ( clean and well treated) and rain ( not treated)
         */
        // weight given to water from borehole
        public void setWaterSourcePreference_Borehole(double r) {
            if (r >= 1.0) {
                r = 1.0;
            }
            this.waterSourcePreferenceBorehole = r;
        }

        public double getWaterSourcePreference_Borehole() {
            return waterSourcePreferenceBorehole;
        }

        public void setWaterSourcePreference_River(double r) {
            double rs = 1 - waterSourcePreferenceBorehole;
            if (r == rs) {
                waterSourcePreferenceRiver = r;
            } else {
                this.waterSourcePreferenceRiver = rs;
            }

        }
        // weight given for water from rainfall

        public double getWaterSourcePreference_River() {
            return waterSourcePreferenceRiver;

        }

        public void setHeaalthFacilityCapacity(int ca) {
            this.healthFacilityCapacity = ca;
        }

        public int getHeaalthFacilityCapacity() {
            return healthFacilityCapacity;
        }

        // frequency of rainfall
        public void setRainfallFrequencyInterval_Days(int r) {
            this.rainfallFrequency = r;
        }

        public int getRainfallFrequencyInterval_Days() {
            return rainfallFrequency;
        }

        // first onset of rainfall
        public void setRainfallFirstDay(int r) {
            this.firstRainfallDay = r;
        }

        public int getRainfallFirstDay() {
            return firstRainfallDay;
        }

        // duration of rainfall
        public void setRainfallDuration_Minute(int r) {
            this.rainDuration = r;
        }

        public int getRainfallDuration_Minute() {
            return rainDuration;
        }
    }
}
