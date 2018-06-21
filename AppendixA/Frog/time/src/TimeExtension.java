import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.TreeSet;
import java.util.TreeMap;
import java.util.LinkedHashMap;
import java.util.Vector;
import java.util.logging.FileHandler;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;

import org.nlogo.agent.AgentSet.Iterator;
import org.nlogo.agent.ArrayAgentSet;
import org.nlogo.agent.Observer;
import org.nlogo.agent.TickCounter;
import org.nlogo.agent.TreeAgentSet;
import org.nlogo.agent.World;
import org.nlogo.api.*;
import org.nlogo.nvm.ExtensionContext;
import org.nlogo.nvm.Workspace.OutputDestination;
import org.joda.time.*;
import org.joda.time.chrono.ISOChronology;
import org.joda.time.format.*;


public class TimeExtension extends org.nlogo.api.DefaultClassManager {

	public enum AddType {
		DEFAULT, SHUFFLE, REPEAT, REPEAT_SHUFFLED
	}
	public enum DateType {
		DATETIME,DATE,DAY
	}
	public enum PeriodType {
		MILLI,SECOND,MINUTE,HOUR,DAY,DAYOFYEAR,DAYOFWEEK,WEEK,MONTH,YEAR
	}
	public enum DataType {
		BOOLEAN,INTEGER,DOUBLE,STRING;
	}
	public enum GetTSMethod{
		EXACT,NEAREST,LINEAR_INTERP;
	}
	public java.util.List<String> additionalJars() {
		java.util.List<String> list = new java.util.ArrayList<String>();
		list.add("joda-time-2.2.jar");
		return list;
	}

	private static final LogoSchedule schedule = new LogoSchedule();
	private static Context context;
	private static long nextEvent = 0;
	private static boolean debug = false;

	public void load(org.nlogo.api.PrimitiveManager primManager) {
		/**********************
		/* TIME PRIMITIVES
		/**********************/
		primManager.addPrimitive("create", new NewLogoTime());
		primManager.addPrimitive("create-with-format", new CreateWithFormat());
		primManager.addPrimitive("anchor-to-ticks", new Anchor());
		primManager.addPrimitive("plus", new Plus());
		primManager.addPrimitive("show", new Show());
		primManager.addPrimitive("get", new Get());
		primManager.addPrimitive("copy", new Copy());
		primManager.addPrimitive("is-before", new IsBefore());
		primManager.addPrimitive("is-after", new IsAfter());
		primManager.addPrimitive("is-equal", new IsEqual());
		primManager.addPrimitive("is-between", new IsBetween());
		primManager.addPrimitive("difference-between", new DifferenceBetween());

		/********************************************
		/* DISCRETE EVENT SIMULATION PRIMITIVES
		/*******************************************/
		primManager.addPrimitive("size-of-schedule", new GetSize());
		primManager.addPrimitive("schedule-event", new AddEvent());
		primManager.addPrimitive("schedule-event-shuffled", new AddEventShuffled());
		primManager.addPrimitive("schedule-repeating-event", new RepeatEvent());
		primManager.addPrimitive("schedule-repeating-event-shuffled", new RepeatEventShuffled());
		primManager.addPrimitive("schedule-repeating-event-with-period", new RepeatEventWithPeriod());
		primManager.addPrimitive("schedule-repeating-event-shuffled-with-period", new RepeatEventShuffledWithPeriod());
		primManager.addPrimitive("anchor-schedule", new AnchorSchedule());
		primManager.addPrimitive("go", new Go());
		primManager.addPrimitive("go-until", new GoUntil());
		primManager.addPrimitive("clear-schedule", new ClearSchedule());

		/**********************
		/* TIME SERIES PRIMITIVES
		/**********************/
		primManager.addPrimitive("ts-create", new TimeSeriesCreate());
		primManager.addPrimitive("ts-load", new TimeSeriesLoad());
		primManager.addPrimitive("ts-load-with-format", new TimeSeriesLoadWithFormat());
		primManager.addPrimitive("ts-write", new TimeSeriesWrite());
		primManager.addPrimitive("ts-get", new TimeSeriesGet());
		primManager.addPrimitive("ts-get-interp", new TimeSeriesGetInterp());
		primManager.addPrimitive("ts-get-exact", new TimeSeriesGetExact());
		primManager.addPrimitive("ts-get-range", new TimeSeriesGetRange());
		primManager.addPrimitive("ts-add-row", new TimeSeriesAddRow());
	}
	public void clearAll() {
		this.schedule.clear();
	}
	public class LogoTimeComparator implements Comparator<LogoTime> {
		public int compare(LogoTime a, LogoTime b) {
			return a.compareTo(b);
		}
	}
	static class TimeSeriesRecord {
		public LogoTime time;
		public int dataIndex;

		TimeSeriesRecord(LogoTime time,int i){
			this.time = time;
			this.dataIndex = i;
		}
	}
	@SuppressWarnings("unchecked")
	static class TimeSeriesColumn {
		public DataType dataType;
		@SuppressWarnings("rawtypes")
		public ArrayList data;

		TimeSeriesColumn(){
		}
		public void add(String value){
			if(this.dataType==null){
				try{
					Double.parseDouble(value);
					this.dataType = DataType.DOUBLE;
					this.data = new ArrayList<Double>();
					this.data.add(Double.parseDouble(value));
				}catch (Exception e3) {
					this.dataType = DataType.STRING;
					this.data = new ArrayList<String>();
					this.data.add(value);
				}
			}else{
				switch(dataType){
				case DOUBLE:
					this.data.add(Double.parseDouble(value));
					break;
				case STRING:
					this.data.add(value);
					break;
				}
			}
		}
	}
	static class LogoTimeSeries implements org.nlogo.api.ExtensionObject {
		TreeMap<LogoTime,TimeSeriesRecord> times = new TreeMap<LogoTime,TimeSeriesRecord>((new TimeExtension()).new LogoTimeComparator());
		LinkedHashMap<String,TimeSeriesColumn> columns = new LinkedHashMap<String,TimeSeriesColumn>();
		Integer numRows = 0;

		LogoTimeSeries(LogoList colNames) throws ExtensionException{
			for(Object colName : colNames){
				columns.put(colName.toString(), new TimeSeriesColumn());
			}
		}
		LogoTimeSeries(String filename, String customFormat, ExtensionContext context) throws ExtensionException{
			parseTimeSeriesFile(filename, customFormat, context);
		}
		LogoTimeSeries(String filename, ExtensionContext context) throws ExtensionException{
			parseTimeSeriesFile(filename, context);
		}
		public void add(LogoTime time, List<Object> list) throws ExtensionException{
			int index = times.size();
			TimeSeriesRecord record = new TimeSeriesRecord(time, index);
			int i = 0;
			for(String colName : columns.keySet()){
				columns.get(colName).add(list.get(i++).toString());
			}
			try{
				times.put(time, record);
			}catch(NullPointerException e){
				if(time.dateType != ((LogoTime)times.keySet().toArray()[0]).dateType){
					throw new ExtensionException("Cannot add a row with a LogoTime of type "+time.dateType.toString()+
							" to a LogoTimeSeries of type "+((LogoTime)times.keySet().toArray()[0]).dateType.toString()+
							".  Note, the first row added to the LogoTimeSeries object determines the data types for all columns.");
				}else{
					throw e;
				}
			}
		}
		public Integer getNumColumns(){
			return columns.size();
		}
		public void write(String filename, ExtensionContext context) throws ExtensionException{
			File dataFile;
			if(filename.charAt(0)=='/' || filename.charAt(0)=='\\'){
				dataFile = new File(filename);
			}else{
				dataFile = new File(context.workspace().getModelDir()+"/"+filename);
			}
			FileWriter fw;
			try {
				fw = new FileWriter(dataFile.getAbsoluteFile());
				BufferedWriter bw = new BufferedWriter(fw);
				bw.write("TIMESTAMP");
				for(String colName : columns.keySet()){
					bw.write("," + colName);
				}
				bw.write("\n");
				for(LogoTime logoTime : times.keySet()){
					TimeSeriesRecord time = times.get(logoTime);
					bw.write(time.time.dump(false,false,false));
					for(String colName : columns.keySet()){
						bw.write("," + columns.get(colName).data.get(time.dataIndex));
					}
					bw.write("\n");
				}
				bw.flush();
				bw.close();
			} catch (IOException e) {
				throw new ExtensionException(e.getMessage());
			}
		}
		public void parseTimeSeriesFile(String filename, ExtensionContext context) throws ExtensionException{
			parseTimeSeriesFile(filename,null,context);
		}
		public void parseTimeSeriesFile(String filename, String customFormat, ExtensionContext context) throws ExtensionException{
			File dataFile;
			if(filename.charAt(0)=='/' || filename.charAt(0)=='\\'){
				dataFile = new File(filename);
			}else{
				dataFile = new File(context.workspace().getModelDir()+"/"+filename);
			}
			FileInputStream fstream;
			try {
				fstream = new FileInputStream(dataFile);
			} catch (FileNotFoundException e) {
				throw new ExtensionException(e.getMessage());
			}
			DataInputStream in = new DataInputStream(fstream);
			BufferedReader br = new BufferedReader(new InputStreamReader(in));
			int lineCount = 0;
			String delim = null, strLine = null;
			String[] lineData;

			// Read the header line after skipping commented lines and infer the delimiter (tab or comma)
			strLine = ";";
			while(strLine.trim().charAt(0)==';'){
				try {
					strLine = br.readLine();
				} catch (IOException e) {
					throw new ExtensionException(e.getMessage());
				}
				if(strLine==null)throw new ExtensionException("File "+dataFile+" is blank.");
			}
			Boolean hasTab = strLine.contains("\t");
			Boolean hasCom = strLine.contains(",");
			if(hasTab && hasCom){
				throw new ExtensionException("Ambiguous file format in file "+dataFile+", the header line contains both a tab and a comma character, expecting one or the other.");
			}else if(hasTab){
				delim = "\t";
			}else if(hasCom){
				delim = ",";
			}else{
				throw new ExtensionException("Illegal file format in file "+dataFile+", the header line does not contain a tab or a comma character, expecting one or the other.");
			}
			// Parse the header and create the column objects (skipping the time column)
			String[] columnNames = strLine.split(delim);
			for(String columnName : Arrays.copyOfRange(columnNames, 1, columnNames.length)){
				columns.put(columnName, new TimeSeriesColumn());
			}
			// Read the rest of the data
			try{
				while ((strLine = br.readLine())!=null){
					lineData = strLine.split(delim);
					LogoTime newTime = new LogoTime(lineData[0],customFormat);
					times.put(newTime,new TimeSeriesRecord(newTime, numRows++));
					for(int colInd = 1; colInd <= columns.size(); colInd++){
						columns.get(columnNames[colInd]).add(lineData[colInd]);
					}
				}
			}catch (IOException e){
				throw new ExtensionException(e.getMessage());
			}
		}
		public Object getByTime(LogoTime time, String columnName, GetTSMethod getMethod) throws ExtensionException{
			ArrayList<String> columnList = new ArrayList<String>(columns.size());
			ArrayList<Object> resultList = new ArrayList<Object>(columns.size());
			if(columnName.equals("ALL_-_COLUMNS")){
				columnList.addAll(columns.keySet());
			}else if(!columns.containsKey(columnName)){
				throw new ExtensionException("The LogoTimeSeries does not contain the column "+columnName);
			}else{
				columnList.add(columnName);
			}
			LogoTime finalKey = null, higherKey = null, lowerKey = null;
			if(times.get(time)!=null){
				finalKey = time;
			}else{
				higherKey = times.higherKey(time);
				lowerKey = times.lowerKey(time);
				if(higherKey == null){
					finalKey = lowerKey;
				}else if(lowerKey == null){
					finalKey = higherKey;
				}else{
					switch(getMethod){
					case EXACT:
						throw new ExtensionException("The LogoTime "+time.dump(false, false, false)+" does not exist in the time series.");
					case NEAREST:
						finalKey = time.isCloserToAThanB(lowerKey, higherKey) ? lowerKey : higherKey;
						break;
					case LINEAR_INTERP:
						finalKey = time;
						break;
					}
				}
			}
			if(columnName.equals("ALL_-_COLUMNS"))resultList.add(finalKey);
			for(String colName : columnList){
				if(getMethod==GetTSMethod.LINEAR_INTERP){
					if(columns.get(colName).data.get(0) instanceof String)throw new ExtensionException("Cannot interpolate between string values, use time:get instead.");
					resultList.add( (Double)columns.get(colName).data.get(times.get(lowerKey).dataIndex) + 
						((Double)columns.get(colName).data.get(times.get(higherKey).dataIndex) - (Double)columns.get(colName).data.get(times.get(lowerKey).dataIndex)) *
						lowerKey.getDifferenceBetween(PeriodType.MILLI, time) / lowerKey.getDifferenceBetween(PeriodType.MILLI, higherKey) );
				}else{
					resultList.add(columns.get(colName).data.get(times.get(finalKey).dataIndex));
				}
			}
			if(resultList.size()==1){
				return resultList.get(0);
			}else{
				return LogoList.fromJava(resultList);
			}
		}
		public Object getRangeByTime(LogoTime timeLow, LogoTime timeHigh, String columnName) throws ExtensionException{
			if(!timeLow.isBefore(timeHigh)){
				LogoTime timeTemp = timeLow;
				timeLow = timeHigh;
				timeHigh = timeTemp;
			}
			ArrayList<String> columnList = new ArrayList<String>(columns.size());
			ArrayList<LogoList> resultList = new ArrayList<LogoList>(columns.size());
			if(columnName.equals("ALL_-_COLUMNS")){
				columnList.addAll(columns.keySet());
			}else if(columnName.equals("LOGOTIME")){
				// do nothing, keep columnList empty
			}else if(!columns.containsKey(columnName)){
				throw new ExtensionException("The LogoTimeSeries does not contain the column "+columnName);
			}else{
				columnList.add(columnName);
			}
			LogoTime lowerKey = timeLow;
			if(times.get(lowerKey) == null) lowerKey = times.higherKey(timeLow);
			LogoTime higherKey = timeHigh;
			if(times.get(higherKey) == null) higherKey = times.lowerKey(timeHigh);
			if(lowerKey == null || higherKey == null){
				if(columnName.equals("ALL_-_COLUMNS") || columnName.equals("LOGOTIME")){
					resultList.add(LogoList.fromVector(new scala.collection.immutable.Vector<Object>(0, 0, 0)));
				}
				for(String colName : columnList){
					resultList.add(LogoList.fromVector(new scala.collection.immutable.Vector<Object>(0, 0, 0)));
				}
			}else{
				if(columnName.equals("ALL_-_COLUMNS") || columnName.equals("LOGOTIME")){
					resultList.add(LogoList.fromJava(times.subMap(lowerKey, true, higherKey, true).keySet()));
				}
				for(String colName : columnList){
					resultList.add(LogoList.fromJava(columns.get(colName).data.subList(times.get(lowerKey).dataIndex, times.get(higherKey).dataIndex+1)));
				}
			}
			if(resultList.size()==1){
				return resultList.get(0);
			}else{
				return LogoList.fromJava(resultList);
			}
		}
		public String dump(boolean arg0, boolean arg1, boolean arg2) {
			String result = "TIMESTAMP";
			for(String colName : columns.keySet()){
				result += "," + colName;
			}
			result += "\n";
			for(LogoTime logoTime : times.keySet()){
				TimeSeriesRecord time = times.get(logoTime);
				result += time.time.dump(false,false,false);
				for(String colName : columns.keySet()){
					result += "," + columns.get(colName).data.get(time.dataIndex);
				}
				result += "\n";
			}
			return result;
		}
		public void ensureDateTypeConsistent(LogoTime time) throws ExtensionException{
			if(times.size()>0){
				if(times.firstKey().dateType != time.dateType){
					throw(new ExtensionException("The LogoTimeSeries contains LogoTimes of type "+times.firstKey().dateType.toString()+
							" while the LogoTime "+time.toString()+" used in the search is of type "+time.dateType.toString()));
				}
			}
		}
		public String getExtensionName() {
			return "time";
		}
		public String getNLTypeName() {
			return "LogoTimeSeries";
		}
		public boolean recursivelyEqual(Object arg0) {
			return false;
		}
	}
	public class LogoEvent implements org.nlogo.api.ExtensionObject {
		private final long id;
		public Double tick = null;
		public org.nlogo.nvm.CommandTask task = null;
		public org.nlogo.agent.AgentSet agents = null;
		public Double repeatInterval = null;
		public PeriodType repeatIntervalPeriodType = null;
		public Boolean shuffleAgentSet = null;

		LogoEvent(org.nlogo.agent.AgentSet agents, CommandTask task, Double tick, Double repeatInterval, PeriodType repeatIntervalPeriodType, Boolean shuffleAgentSet) {
			this.agents = agents;
			this.task = (org.nlogo.nvm.CommandTask) task;
			this.tick = tick;
			this.repeatInterval = repeatInterval;
			this.repeatIntervalPeriodType = repeatIntervalPeriodType;
			this.shuffleAgentSet = shuffleAgentSet;
			this.id = nextEvent;
			nextEvent++;
		}
		public void replaceData(Agent agent, CommandTask task, Double tick) {
			this.agents = agents;
			this.task = (org.nlogo.nvm.CommandTask) task;
			this.tick = tick;
		}
		/*
		 * If a repeatInterval is set, this method uses it to update it's tick field and then adds itself to the
		 * schedule argument.  The return value indicates whether the event was added to the schedule again.
		 */
		public Boolean reschedule(LogoSchedule callingSchedule) throws ExtensionException{
			if(repeatInterval == null)return false;
			if(repeatIntervalPeriodType == null){ // in this case we assume that repeatInterval is in the same units as tick
				this.tick = this.tick + repeatInterval;
			}else{
				LogoTime currentTime = callingSchedule.getCurrentTime();
				if(debug)printToConsole(context, "resheduling: "+ repeatInterval + " " + repeatIntervalPeriodType + " ahead of " + currentTime + " or " + currentTime.getDifferenceBetween(callingSchedule.tickType, currentTime.plus(repeatIntervalPeriodType, repeatInterval))/callingSchedule.tickValue);
				this.tick = this.tick + currentTime.getDifferenceBetween(callingSchedule.tickType, currentTime.plus(repeatIntervalPeriodType, repeatInterval))/callingSchedule.tickValue;
				if(debug)printToConsole(context, "event scheduled for tick: " + this.tick); 
			}
			return schedule.scheduleTree.add(this);
		}
		public boolean equals(Object obj) {
			return this == obj;
		}
		public String getExtensionName() {
			return "time";
		}
		public String getNLTypeName() {
			return "event";
		}
		public boolean recursivelyEqual(Object arg0) {
			return equals(arg0);
		}
		public String dump(boolean arg0, boolean arg1, boolean arg2) {
			return tick + ((agents==null)?"observer":agents.toString()) + ((task==null)?"":task.toString()) + ((repeatInterval==null)?"":repeatInterval.toString());
		}
	}
	private static class LogoSchedule implements org.nlogo.api.ExtensionObject {
		LogoEventComparator comparator = (new TimeExtension()).new LogoEventComparator();
		TreeSet<LogoEvent> scheduleTree = new TreeSet<LogoEvent>(comparator);
		TickCounter tickCounter = null;
		
		// The following three fields track an anchored schedule
		LogoTime timeAnchor = null;
		PeriodType tickType = null;
		Double tickValue = null;

		LogoSchedule() {
		}
		public boolean equals(Object obj) {
			return this == obj;
		}
		public boolean isAnchored(){
			return timeAnchor != null;
		}
		public void anchorSchedule(LogoTime time, Double tickValue, PeriodType tickType){
			try {
				this.timeAnchor = new LogoTime(time);
				this.tickType = tickType;
				this.tickValue = tickValue;
				this.tickCounter = ((ExtensionContext)context).workspace().world().tickCounter;
			} catch (ExtensionException e) {
				e.printStackTrace();
			}
		}
		public Double timeToTick(LogoTime time) throws ExtensionException{
			if(this.timeAnchor.dateType != time.dateType)throw new ExtensionException("Cannot schedule event to occur at a LogoTime of type "+time.dateType.toString()+" because the schedule is anchored to a LogoTime of type "+this.timeAnchor.dateType.toString()+".  Types must be consistent.");
			return this.timeAnchor.getDifferenceBetween(this.tickType, time)/this.tickValue;
		}
		public void addEvent(Argument args[], Context context, AddType addType) throws ExtensionException, LogoException {
			String primName = null;
			Double eventTick = null;
			switch(addType){
			case DEFAULT:
				primName = "add";
				if(args.length<3)throw new ExtensionException("time:add must have 3 arguments: schedule agent task tick/time");
				break;
			case SHUFFLE:
				primName = "add-shuffled";
				if(args.length<3)throw new ExtensionException("time:add-shuffled must have 3 arguments: schedule agent task tick/time");
				break;
			case REPEAT:
				primName = "repeat";
				if(args.length<4)throw new ExtensionException("time:repeat must have 4 or 5 arguments: schedule agent task tick/time number (period-type)");
				break;
			case REPEAT_SHUFFLED:
				primName = "repeat-shuffled";
				if(args.length<4)throw new ExtensionException("time:repeat-shuffled must have 4 or 5 arguments: schedule agent task tick/time number (period-type)");
				break;
			}
			if (!(args[0].get() instanceof Agent) && !(args[0].get() instanceof AgentSet) && !((args[0].get() instanceof String) && args[0].get().toString().toLowerCase().equals("observer"))) 
				throw new ExtensionException("time:"+primName+" expecting an agent, agentset, or the string \"observer\" as the first argument");
			if (!(args[1].get() instanceof CommandTask)) throw new ExtensionException("time:"+primName+" expecting a command task as the second argument");
			if(args[2].get().getClass().equals(Double.class)){
				eventTick = args[2].getDoubleValue();
			}else if(args[2].get().getClass().equals(LogoTime.class)){
				if(!this.isAnchored())throw new ExtensionException("A LogoEvent can only be scheduled to occur at a LogoTime if the discrete event schedule has been anchored to a LogoTime, see time:anchor-schedule");
				eventTick = this.timeToTick(getTimeFromArgument(args, 2));
			}else{
				throw new ExtensionException("time:"+primName+" expecting a number or logotime as the third argument");
			}
			if (eventTick < ((ExtensionContext)context).workspace().world().ticks()) throw new ExtensionException("Attempted to schedule an event for tick "+ eventTick +" which is before the present 'moment' of "+((ExtensionContext)context).workspace().world().ticks());
			
			TimeExtension.PeriodType repeatIntervalPeriodType = null;
			Double repeatInterval = null;
			if(addType == AddType.REPEAT || addType == AddType.REPEAT_SHUFFLED){
				if (!args[3].get().getClass().equals(Double.class)) throw new ExtensionException("time:repeat expecting a number as the fourth argument");
				repeatInterval = args[3].getDoubleValue();
				if (repeatInterval <= 0) throw new ExtensionException("time:repeat the repeat interval must be a positive number");
				if(args.length == 5){
					if(!this.isAnchored())throw new ExtensionException("A LogoEvent can only be scheduled to repeat using a period type if the discrete event schedule has been anchored to a LogoTime, see time:anchor-schedule");
					repeatIntervalPeriodType = stringToPeriodType(getStringFromArgument(args, 4));
					if(repeatIntervalPeriodType != TimeExtension.PeriodType.MONTH && repeatIntervalPeriodType != TimeExtension.PeriodType.YEAR){
						repeatInterval = this.timeAnchor.getDifferenceBetween(this.tickType, this.timeAnchor.plus(repeatIntervalPeriodType, repeatInterval))/this.tickValue;
						if(debug)printToConsole(context, "from:"+repeatIntervalPeriodType+" to:"+this.tickType+" interval:"+repeatInterval);
						repeatIntervalPeriodType = null;
					}else{
						if(debug)printToConsole(context, "repeat every: "+ repeatInterval + " " + repeatIntervalPeriodType);
					}
				}
			}
			Boolean shuffleAgentSet = (addType == AddType.SHUFFLE || addType == AddType.REPEAT_SHUFFLED);

			org.nlogo.agent.AgentSet agentSet = null;
			if (args[0].get() instanceof org.nlogo.agent.Agent){
				org.nlogo.agent.Agent theAgent = (org.nlogo.agent.Agent)args[0].getAgent();
				agentSet = new ArrayAgentSet(theAgent.getAgentClass(),1,false,(World) theAgent.world());
				agentSet.add(theAgent);
			}else if(args[0].get() instanceof AgentSet){
				agentSet = (org.nlogo.agent.AgentSet) args[0].getAgentSet();
			}else{
				// leave agentSet as null to signal observer should be used
			}
			LogoEvent event = (new TimeExtension()).new LogoEvent(agentSet,args[1].getCommandTask(),eventTick,repeatInterval,repeatIntervalPeriodType,shuffleAgentSet);
			if(debug)printToConsole(context,"scheduling event: "+event.dump(false, false, false));
			scheduleTree.add(event);
		}
		public void performScheduledTasks(Argument args[], Context context) throws ExtensionException, LogoException {
			performScheduledTasks(args,context,Double.MAX_VALUE);
		}	
		public void performScheduledTasks(Argument args[], Context context, LogoTime untilTime) throws ExtensionException, LogoException {
			if(!this.isAnchored())throw new ExtensionException("time:go-until can only accept a LogoTime as a stopping time if the schedule is anchored using time:anchore-schedule");
			if(debug)printToConsole(context,"timeAnchor: "+this.timeAnchor+" tickType: "+this.tickType+" tickValue:"+this.tickValue + " untilTime:" + untilTime);
			Double untilTick = this.timeAnchor.getDifferenceBetween(this.tickType, untilTime)/this.tickValue;
			performScheduledTasks(args,context,untilTick);
		}
		public void performScheduledTasks(Argument args[], Context context, Double untilTick) throws ExtensionException, LogoException {
			ExtensionContext extcontext = (ExtensionContext) context;
			Object[] emptyArgs = new Object[0]; // This extension is only for CommandTasks, so we know there aren't any args to pass in
			LogoEvent event = scheduleTree.isEmpty() ? null : scheduleTree.first();
			ArrayList<org.nlogo.agent.Agent> theAgents = new ArrayList<org.nlogo.agent.Agent>();
			while(event != null && event.tick <= untilTick){
				if(debug)printToConsole(context,"performing event-id: "+event.id+" for agent: "+event.agents+" at tick:"+event.tick + " ");
				tickCounter.tick(event.tick-tickCounter.ticks());

				if(event.agents == null){
					org.nlogo.nvm.Context nvmContext = new org.nlogo.nvm.Context(extcontext.nvmContext().job,
																					(org.nlogo.agent.Agent)extcontext.getAgent().world().observer(),
																					extcontext.nvmContext().ip,
																					extcontext.nvmContext().activation);
					event.task.perform(nvmContext, emptyArgs);
				}else if(event.shuffleAgentSet){
					Iterator iter = event.agents.shufflerator(extcontext.nvmContext().job.random);
					while(iter.hasNext()){
						org.nlogo.nvm.Context nvmContext = new org.nlogo.nvm.Context(extcontext.nvmContext().job,iter.next(),extcontext.nvmContext().ip,extcontext.nvmContext().activation);
//						if(extcontext.nvmContext().stopping)return;
						event.task.perform(nvmContext, emptyArgs);
//						if(nvmContext.stopping)return;
					}
				}else{
					org.nlogo.agent.Agent[] source = null;
					org.nlogo.agent.Agent[] copy = null;
					if(event.agents instanceof ArrayAgentSet){
						source = event.agents.toArray();
						copy = new org.nlogo.agent.Agent[event.agents.count()];
						System.arraycopy(source, 0, copy, 0, source.length);
					}else if(event.agents instanceof TreeAgentSet){
						copy = event.agents.toArray();
					}
					for(org.nlogo.agent.Agent theAgent : copy){
						if(theAgent == null || theAgent.id == -1)continue;
						org.nlogo.nvm.Context nvmContext = new org.nlogo.nvm.Context(extcontext.nvmContext().job,theAgent,extcontext.nvmContext().ip,extcontext.nvmContext().activation);
//						if(extcontext.nvmContext().stopping)return;
						event.task.perform(nvmContext, emptyArgs);
//						if(nvmContext.stopping)return;
					}
				}

				// Remove the current event as is from the schedule
				scheduleTree.remove(event);

				// Reschedule the event if necessary
				event.reschedule(this);

				// Grab the next event from the schedule
				event = scheduleTree.isEmpty() ? null : scheduleTree.first();
			}
			if(untilTick < Double.MAX_VALUE && untilTick > tickCounter.ticks()) tickCounter.tick(untilTick-tickCounter.ticks());
		}
		public LogoTime getCurrentTime() throws ExtensionException{
			if(!this.isAnchored())return null;
			if(debug)printToConsole(context, "current time is: " + this.timeAnchor.plus(this.tickType,tickCounter.ticks() / this.tickValue));
			return this.timeAnchor.plus(this.tickType,tickCounter.ticks() / this.tickValue);
		}
		public String dump(boolean readable, boolean exporting, boolean reference) {
			StringBuilder buf = new StringBuilder();
			if (exporting) {
				buf.append("LogoSchedule");
				if (!reference) {
					buf.append(":");
				}
			}
			if (!(reference && exporting)) {
				buf.append(" [ ");
				java.util.Iterator iter = scheduleTree.iterator();
				while(iter.hasNext()){
					buf.append(((LogoEvent)iter.next()).dump(true, true, true));
					buf.append(" ");
				}
				buf.append("]");
			}
			return buf.toString();
		}
		public String getExtensionName() {
			return "time";
		}
		public String getNLTypeName() {
			return "schedule";
		}
		public boolean recursivelyEqual(Object arg0) {
			return equals(arg0);
		}
		public void clear() {
			scheduleTree.clear();
		}
	}
	/*
	 * The LogoEventComparator first compares based on tick (which is a Double) and then on id 
	 * so if there is a tie for tick, the event that was created first get's executed first allowing
	 * for a more intuitive execution.
	 */
	public class LogoEventComparator implements Comparator<LogoEvent> {
		public int compare(LogoEvent a, LogoEvent b) {
			if(a.tick < b.tick){
				return -1;
			}else if(a.tick > b.tick){
				return 1;
			}else if(a.id < b.id){
				return -1;
			}else if(a.id > b.id){
				return 1;
			}else{
				return 0;
			}
		}
	}
	private static class LogoTime implements org.nlogo.api.ExtensionObject {
		public DateType			dateType = null;
		public LocalDateTime 	datetime = null;
		public LocalDate 		date	 = null;
		public MonthDay 		monthDay = null;
		private DateTimeFormatter customFmt = null;
		private DateTimeFormatter defaultFmt = null;
		private Boolean 		isAnchored = false;
		private Double 			tickValue;
		private PeriodType 		tickType;
		private LocalDateTime 	anchorDatetime;
		private LocalDate 		anchorDate;
		private MonthDay 		anchorMonthDay;
		private World 			world;

		LogoTime(LogoTime time) throws ExtensionException {
			this(time.show(time.defaultFmt));
		}
		LogoTime(LocalDateTime dt) {
			this.datetime = dt;
			this.defaultFmt = DateTimeFormat.forPattern("yyyy-MM-dd HH:mm:ss.SSS");
			this.dateType = DateType.DATETIME;
		}
		LogoTime(LocalDate dt) {
			this.date = dt;
			this.defaultFmt = DateTimeFormat.forPattern("yyyy-MM-dd");
			this.dateType = DateType.DATE;
		}
		LogoTime(MonthDay dt) {
			this.monthDay = dt;
			this.defaultFmt = DateTimeFormat.forPattern("MM-dd");
			this.dateType = DateType.DAY;
		}
		LogoTime(String dateString) throws ExtensionException {
			this(dateString,null);
		}
		LogoTime(String dateString, String customFormat) throws ExtensionException {
			// First we parse the string to determine the date type
			if(customFormat == null){
				dateString = parseDateString(dateString);
			}else{
				if(customFormat.indexOf('H') >= 0 ||
					customFormat.indexOf('h') >= 0 || 
					customFormat.indexOf('K') >= 0 || 
					customFormat.indexOf('k') >= 0){
					this.dateType = DateType.DATETIME;
				}else if(customFormat.indexOf('Y') >= 0 || customFormat.indexOf('y') >= 0){
					this.dateType = DateType.DATE;
				}else{
					this.dateType = DateType.DAY;
				}
			}
			// Now initialize the defaultFmt
			switch(this.dateType){
			case DATETIME:
				this.defaultFmt = DateTimeFormat.forPattern("yyyy-MM-dd HH:mm:ss.SSS");
				break;
			case DATE:
				this.defaultFmt = DateTimeFormat.forPattern("yyyy-MM-dd");
				break;
			case DAY:
				this.defaultFmt = DateTimeFormat.forPattern("MM-dd");
				break;
			}
			// Now create the joda time object
			if(customFormat == null){
				switch(this.dateType){
				case DATETIME:
					this.datetime = (dateString.length() == 0 || dateString.equals("now")) ? new LocalDateTime() : new LocalDateTime(dateString);
					break;
				case DATE:
					this.date = new LocalDate(dateString);
					break;
				case DAY:
					this.monthDay = (new MonthDay()).parse(dateString, this.defaultFmt);
					break;
				}
			}else{
				this.customFmt = DateTimeFormat.forPattern(customFormat);
				switch(this.dateType){
				case DATETIME:
					this.datetime = LocalDateTime.parse(dateString, this.customFmt);
					break;
				case DATE:
					this.date = LocalDate.parse(dateString, this.customFmt);
					break;
				case DAY:
					this.monthDay = MonthDay.parse(dateString, this.customFmt);
					break;
				}
				if(debug)printToConsole(getContext(), customFormat);
				if(debug)printToConsole(getContext(), dateString);
			}
		}
		int compareTo(LogoTime that){
			switch(this.dateType){
			case DATETIME:
				return this.datetime.compareTo(that.datetime);
			case DATE:
				return this.date.compareTo(that.date);
			case DAY:
				return this.monthDay.compareTo(that.monthDay);
			}
			return -999;
		}
		public Boolean isCloserToAThanB(LogoTime timeA, LogoTime timeB){
			DateTime refDateTime = new DateTime(ISOChronology.getInstanceUTC());
			Long millisToA = null, millisToB = null;

			switch(this.dateType){
			case DATETIME:
				millisToA = Math.abs((new Duration(timeA.datetime.toDateTime(refDateTime),this.datetime.toDateTime(refDateTime))).getMillis());
				millisToB = Math.abs((new Duration(timeB.datetime.toDateTime(refDateTime),this.datetime.toDateTime(refDateTime))).getMillis());
				break;
			case DATE:
				millisToA = Math.abs((new Duration(timeA.date.toDateTime(refDateTime),this.date.toDateTime(refDateTime))).getMillis());
				millisToB = Math.abs((new Duration(timeB.date.toDateTime(refDateTime),this.date.toDateTime(refDateTime))).getMillis());
				break;
			case DAY:
				millisToA = Math.abs((new Duration(timeA.monthDay.toLocalDate(2000).toDateTime(refDateTime),this.monthDay.toLocalDate(2000).toDateTime(refDateTime))).getMillis());
				millisToB = Math.abs((new Duration(timeB.monthDay.toLocalDate(2000).toDateTime(refDateTime),this.monthDay.toLocalDate(2000).toDateTime(refDateTime))).getMillis());
				break;
			}
			return millisToA < millisToB;
		}
		/* 
		 * parseDateString
		 * 
		 * Accommodate shorthand and human readability, allowing substitution of space for 'T' and '/' for '-'.
		 * Also accommodate all three versions of specifying a full DATETIME (month, day, week -based) but only
		 * allow one specific way each to specify a DATE and a DAY. Single digit months, days, and hours are ok, but single
		 * digit minutes and seconds need a preceding zero (e.g. '06', not '6')
		 * 
		 * LEGIT
		 * 2012-11-10T09:08:07.654
		 * 2012-11-10T9:08:07.654
		 * 2012/11/10T09:08:07.654
		 * 2012-11-10 09:08:07.654
		 * 2012-11-10 9:08:07.654
		 * 2012/11/10 09:08:07.654
		 * 2012-11-10 09:08:07		// assumes 0 for millis
		 * 2012-11-10 09:08			// assumes 0 for seconds and millis
		 * 2012-11-10 09			// assumes 0 for minutes, seconds, and millis
		 * 2012-1-1 09:08:07.654
		 * 2012-01-1 09:08:07.654
		 * 2012-1-01 09:08:07.654
		 * 2012-01-01
		 * 2012-1-01
		 * 2012-01-1
		 * 01-01
		 * 1-01
		 * 01-1
		 * 
		 * NOT LEGIT
		 * 2012-11-10 09:8:07.654
		 * 2012-11-10 09:08:7.654
		 */
		//
		//
		String parseDateString(String dateString) throws ExtensionException{
			dateString = dateString.replace('/', '-').replace(' ', 'T').trim();
			int len = dateString.length();
			// First add 0's to pad single digit months / days if necessary
			int firstDash = dateString.indexOf('-');
			if(firstDash == 1 || firstDash == 2){ // DAY 
				if(firstDash == 1){ // month is single digit
					dateString = "0" + dateString;
					len++;
				}
				// Now check the day for a single digit
				if(len == 4){
					dateString = dateString.substring(0, 3) + "0" + dateString.substring(3, 4);
					len++;
				}else if(len < 5){
					throw new ExtensionException("Illegal time string: '" + dateString + "'"); 
				}
			}else if(firstDash != 4 && firstDash != -1){
				throw new ExtensionException("Illegal time string: '" + dateString + "'"); 
			}else{ // DATETIME or DATE
				int secondDash = dateString.lastIndexOf('-');
				if(secondDash == 6){ // month is single digit
					dateString = dateString.substring(0, 5) + "0" + dateString.substring(5, len);
					len++;
				}
				if(len == 9 || dateString.indexOf('T') == 9){ // day is single digit
					dateString = dateString.substring(0, 8) + "0" + dateString.substring(8, len);
					len++;
				}
				if(dateString.indexOf('T') == 10 & (dateString.indexOf(':') == 12 || len == 12)){ 
					// DATETIME without leading 0 on hour, pad it
					int firstColon = dateString.indexOf(':');
					dateString = dateString.substring(0, 11) + "0" + dateString.substring(11, len);
					len++;
				}
			}
			if(len == 23 || len ==21 || len == 3 || len == 0){ // a full DATETIME
				this.dateType = DateType.DATETIME;
			}else if(len == 19 || len == 17){ // a DATETIME without millis
				this.dateType = DateType.DATETIME;
				dateString += ".000"; 
			}else if(len == 16 || len == 14){ // a DATETIME without seconds or millis
				this.dateType = DateType.DATETIME;
				dateString += ":00.000"; 
			}else if(len == 13 || len == 11){ // a DATETIME without minutes, seconds or millis
				this.dateType = DateType.DATETIME;
				dateString += ":00:00.000"; 
			}else if(len == 10){ // a DATE
				this.dateType = DateType.DATE;
			}else if(len == 5){ // a DAY
				this.dateType = DateType.DAY;
			}else{
				throw new ExtensionException("Illegal time string: '" + dateString + "'"); 
			}
			return dateString;
		}
		public void setAnchor(Double tickCount, PeriodType tickType, World world) throws ExtensionException{
			if(tickType == PeriodType.DAYOFWEEK)throw new ExtensionException(tickType.toString() + " type is not a supported tick type");
			this.isAnchored = true;
			this.tickValue = tickCount;
			this.tickType = tickType;
			switch(this.dateType){
			case DATETIME:
				this.anchorDatetime = new LocalDateTime(this.datetime);
				break;
			case DATE:
				this.anchorDate = new LocalDate(this.date);
				break;
			case DAY:
				this.anchorMonthDay = new MonthDay(this.monthDay);
				break;
			}
			this.world = world;
		}
		public String dump(boolean arg1, boolean arg2, boolean arg3) {
			return this.toString();
		}
		public String toString(){
			try {
				this.updateFromTick();
			} catch (ExtensionException e) {
				// ignore
			}
			switch(this.dateType){
			case DATETIME:
				return datetime.toString(this.customFmt == null ? this.defaultFmt : this.customFmt);
			case DATE:
				return date.toString(this.customFmt == null ? this.defaultFmt : this.customFmt);
			case DAY:
				return monthDay.toString(this.customFmt == null ? this.defaultFmt : this.customFmt);
			}
			return "";
		}

		public void updateFromTick() throws ExtensionException {
			if(!this.isAnchored)return;

			switch(this.dateType){
			case DATETIME:
				this.datetime = this.plus(this.anchorDatetime,this.tickType, this.world.ticks()*this.tickValue).datetime;
				break;
			case DATE:
				this.date = this.plus(this.anchorDate,this.tickType, this.world.ticks()*this.tickValue).date;
				break;
			case DAY:
				this.monthDay = this.plus(this.anchorMonthDay,this.tickType, this.world.ticks()*this.tickValue).monthDay;
				break;
			}
		}
		public String getExtensionName() {
			return "time";
		}
		public String getNLTypeName() {
			return "logotime";
		}
		public boolean recursivelyEqual(Object arg0) {
			return equals(arg0);
		}
		public String show(DateTimeFormatter fmt){
			return (this.date == null) ? this.datetime.toString(fmt) : this.date.toString(fmt);
		}
		public Integer get(PeriodType periodType) throws ExtensionException{
			Integer result = null;
			try{
				switch(periodType){
				case MILLI:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getMillisOfSecond();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.millisOfSecond());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.millisOfSecond());
						break;
					}
					break;
				case SECOND:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getSecondOfMinute();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.secondOfMinute());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.secondOfMinute());
						break;
					}
					break;
				case MINUTE:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getMinuteOfHour();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.minuteOfHour());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.minuteOfHour());
						break;
					}
					break;
				case HOUR:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getHourOfDay();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.hourOfDay());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.hourOfDay());
						break;
					}
					break;
				case DAY:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getDayOfMonth();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.dayOfMonth());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.dayOfMonth());
						break;
					}
					break;
				case DAYOFYEAR:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getDayOfYear();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.dayOfYear());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.dayOfYear());
						break;
					}
					break;
				case DAYOFWEEK:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getDayOfWeek();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.dayOfWeek());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.dayOfWeek());
						break;
					}
					break;
				case WEEK:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getWeekOfWeekyear();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.weekOfWeekyear());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.weekOfWeekyear());
						break;
					}
					break;
				case MONTH:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getMonthOfYear();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.monthOfYear());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.monthOfYear());
						break;
					}
					break;
				case YEAR:
					switch(this.dateType){
					case DATETIME:
						result =  datetime.getYear();
						break;
					case DATE:
						result =  date.get(DateTimeFieldType.year());
						break;
					case DAY:
						result =  monthDay.get(DateTimeFieldType.year());
						break;
					}
					break;
				}
			}catch(IllegalArgumentException e){
				throw new ExtensionException("Period type "+periodType.toString()+" is not defined for the time "+this.dump(true,true,true));
			}
			return result;
		}
		public LogoTime plus(PeriodType pType, Double durVal) throws ExtensionException{
			switch(this.dateType){
			case DATETIME:
				return this.plus(this.datetime,pType,durVal);
			case DATE:
				return this.plus(this.date,pType,durVal);
			case DAY:
				return this.plus(this.monthDay,pType,durVal);
			}
			return null;
		}
		public LogoTime plus(Object refTime, PeriodType pType, Double durVal) throws ExtensionException{
			Period per = null;
			switch(pType){
			case WEEK:
				durVal *= 7;
			case DAY:
			case DAYOFYEAR:
				durVal *= 24;
			case HOUR:
				durVal *= 60;
			case MINUTE:
				durVal *= 60;
			case SECOND:
				durVal *= 1000;
			case MILLI:
				break;
			case MONTH:
				per = new Period(0,roundDouble(durVal),0,0,0,0,0,0);
				break;
			case YEAR:
				per = new Period(roundDouble(durVal),0,0,0,0,0,0,0);
				break;
			default:
				throw new ExtensionException(pType+" type is not supported by the time:plus primitive");
			}
			switch(this.dateType){
			case DATETIME:
				if(per==null){
					return new LogoTime(((LocalDateTime)refTime).plus(new Duration(dToL(durVal))));
				}else{
					return new LogoTime(((LocalDateTime)refTime).plus(per));
				}
			case DATE:
				if(per==null){
					Integer dayDurVal = ((Double)(durVal / (24.0*60.0*60.0*1000.0))).intValue();
					return new LogoTime(((LocalDate)refTime).plusDays(dayDurVal));
				}else{
					return new LogoTime(((LocalDate)refTime).plus(per));
				}
			case DAY:
				if(per==null){
					Integer dayDurVal = ((Double)(durVal / (24.0*60.0*60.0*1000.0))).intValue();
					return new LogoTime(((MonthDay)refTime).plusDays(dayDurVal));
				}else{
					return new LogoTime(((MonthDay)refTime).plus(per));
				}
			}
			return null;
		}
		public boolean isBefore(LogoTime timeB)throws ExtensionException{
			if(this.dateType != timeB.dateType)throw new ExtensionException("time comparisons only work if the LogoTime's are the same variety, but you called with a "+this.dateType.toString()+" and a "+timeB.dateType.toString());
			switch(this.dateType){
			case DATETIME:
				return this.datetime.isBefore(timeB.datetime);
			case DATE:
				return this.date.isBefore(timeB.date);
			case DAY:
				return this.monthDay.isBefore(timeB.monthDay);
			}
			return true;
		}
		public boolean isEqual(LogoTime timeB)throws ExtensionException{
			if(this.dateType != timeB.dateType)throw new ExtensionException("time comparisons only work if the LogoTime's are the same variety, but you called with a "+this.dateType.toString()+" and a "+timeB.dateType.toString());
			switch(this.dateType){
			case DATETIME:
				return this.datetime.isEqual(timeB.datetime);
			case DATE:
				return this.date.isEqual(timeB.date);
			case DAY:
				return this.monthDay.isEqual(timeB.monthDay);
			}
			return true;
		}
		public boolean isBetween(LogoTime timeA, LogoTime timeB)throws ExtensionException{
			if(!timeA.isBefore(timeB)){
				LogoTime tempA = timeA;
				timeA = timeB;
				timeB = tempA;
			}
			if(this.dateType != timeA.dateType || this.dateType != timeB.dateType)throw new ExtensionException("time comparisons only work if the LogoTime's are the same variety, but you called with a "+
					this.dateType.toString()+", a "+timeA.dateType.toString()+", and a "+timeB.dateType.toString());
			switch(this.dateType){
			case DATETIME:
				return ((this.datetime.isAfter(timeA.datetime) && this.datetime.isBefore(timeB.datetime)) || this.datetime.isEqual(timeA.datetime) || this.datetime.isEqual(timeB.datetime));
			case DATE:
				return ((this.date.isAfter(timeA.date) && this.date.isBefore(timeB.date)) || this.date.isEqual(timeA.date) || this.date.isEqual(timeB.date));
			case DAY:
				return ((this.monthDay.isAfter(timeA.monthDay) && this.monthDay.isBefore(timeB.monthDay)) || this.monthDay.isEqual(timeA.monthDay) || this.monthDay.isEqual(timeB.monthDay));
			}
			return true;
		}
		public Double getDifferenceBetween(PeriodType pType, LogoTime endTime)throws ExtensionException{
			if(this.dateType != endTime.dateType)throw new ExtensionException("time comparisons only work if the LogoTimes are the same variety, but you called with a "+
					this.dateType.toString()+" and a "+endTime.dateType.toString());
			Double durVal = 1.0;
			switch(pType){
			case YEAR:
				switch(this.dateType){
				case DATETIME:
					return intToDouble((new Period(this.datetime,endTime.datetime)).getYears());
				case DATE:
					return intToDouble((new Period(this.date,endTime.date)).getYears());
				case DAY:
					throw new ExtensionException(pType+" type is not supported by the time:difference-between primitive with LogoTimes of type DAY");
				}
			case MONTH:
				switch(this.dateType){
				case DATETIME:
					return intToDouble(Months.monthsBetween(this.datetime,endTime.datetime).getMonths());
				case DATE:
					return intToDouble(Months.monthsBetween(this.date,endTime.date).getMonths());
				case DAY:
					return intToDouble((new Period(this.monthDay,endTime.monthDay)).getMonths());
				}
			case WEEK:
				durVal /= 7.0;
			case DAY:
			case DAYOFYEAR:
				durVal /= 24.0;
			case HOUR:
				durVal /= 60.0;
			case MINUTE:
				durVal /= 60.0;
			case SECOND:
				durVal /= 1000.0;
			case MILLI:
				DateTime refDateTime = new DateTime(ISOChronology.getInstanceUTC());
				switch(this.dateType){
				case DATETIME:
					return durVal * (new Duration(this.datetime.toDateTime(refDateTime),endTime.datetime.toDateTime(refDateTime))).getMillis();
				case DATE:
					return durVal * (new Duration(this.date.toDateTime(refDateTime),endTime.date.toDateTime(refDateTime))).getMillis();
				case DAY:
					return durVal * (new Duration(this.monthDay.toLocalDate(2000).toDateTime(refDateTime),endTime.monthDay.toLocalDate(2000).toDateTime(refDateTime))).getMillis();
				}
			default:
				throw new ExtensionException(pType+" type is not supported by the time:difference-between primitive");
			}
		}
	}

	/***********************
	 * Convenience Methods
	 ***********************/
	private static Long dToL(double d){
		return ((Double)d).longValue();
	}
	private static TimeExtension.PeriodType stringToPeriodType(String sType) throws ExtensionException{
		sType = sType.trim().toLowerCase();
		if(sType.substring(sType.length()-1).equals("s"))sType = sType.substring(0,sType.length()-1);
		if(sType.equals("milli")){
			return PeriodType.MILLI;
		}else if(sType.equals("second")){
			return PeriodType.SECOND;
		}else if(sType.equals("minute")){
			return PeriodType.MINUTE;
		}else if(sType.equals("hour")){
			return PeriodType.HOUR;
		}else if(sType.equals("day") || sType.equals("dayofmonth") || sType.equals("dom")){
			return PeriodType.DAY;
		}else if(sType.equals("doy") || sType.equals("dayofyear") || sType.equals("julianday") || sType.equals("jday")){
			return PeriodType.DAYOFYEAR;
		}else if(sType.equals("dayofweek") || sType.equals("dow") || sType.equals("weekday") || sType.equals("wday")){
			return PeriodType.DAYOFWEEK;
		}else if(sType.equals("week")){
			return PeriodType.WEEK;
		}else if(sType.equals("month")){
			return PeriodType.MONTH;
		}else if(sType.equals("year")){
			return PeriodType.YEAR;
		}else{
			throw new ExtensionException("illegal time period type: "+sType);
		}
	}
	private static LogoTime getTimeFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		LogoTime time = null;
		Object obj = args[argIndex].get();
		if (obj instanceof String) {
			time = new LogoTime(args[argIndex].getString());
		}else if (obj instanceof LogoTime) {
			time = (LogoTime) obj;
		}else{			
			throw new ExtensionException("time: was expecting a LogoTime object as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		time.updateFromTick();
		return time;
	}
	private static Double getDoubleFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		Object obj = args[argIndex].get();
		if (!(obj instanceof Double)) {
			throw new ExtensionException("time: was expecting a number as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		return (Double) obj;
	}
	private static LogoList getListFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		Object obj = args[argIndex].get();
		if (!(obj instanceof LogoList)) {
			throw new ExtensionException("time: was expecting a list as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		return (LogoList) obj;
	}
	private static Integer getIntFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		Object obj = args[argIndex].get();
		if (obj instanceof Double) {
			// Round to nearest int
			return roundDouble((Double)obj);
		}else if (!(obj instanceof Integer)) {
			throw new ExtensionException("time: was expecting a number as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		return (Integer) obj;
	}
	private static Long getLongFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		Object obj = args[argIndex].get();
		if (obj instanceof Double) {
			return ((Double)obj).longValue();
		}else if (!(obj instanceof Integer)) {
			throw new ExtensionException("time: was expecting a number as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		return (Long) obj;
	}
	private static String getStringFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		Object obj = args[argIndex].get();
		if (!(obj instanceof String)) {
			throw new ExtensionException("time: was expecting a string as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		return (String) obj;
	}
	private static LogoTimeSeries getTimeSeriesFromArgument(Argument args[], Integer argIndex) throws ExtensionException, LogoException {
		LogoTimeSeries ts = null;
		Object obj = args[argIndex].get();
		if (obj instanceof LogoTimeSeries) {
			ts = (LogoTimeSeries)obj;
		}else{
			throw new ExtensionException("time: was expecting a LogoTimeSeries object as argument "+(argIndex+1)+", found this instead: " + Dump.logoObject(obj));
		}
		return ts;
	}
	private static Integer roundDouble(Double d){
		return ((Long)Math.round(d)).intValue();
	}
	private static Double intToDouble(int i){
		return (new Integer(i)).doubleValue();
	}
	private static void printToLogfile(String msg){
		Logger logger = Logger.getLogger("MyLog");  
		FileHandler fh;  

		try {  
			// This block configure the logger with handler and formatter  
			fh = new FileHandler("logfile.txt",true);
			logger.addHandler(fh);  
			//logger.setLevel(Level.ALL);  
			SimpleFormatter formatter = new SimpleFormatter();  
			fh.setFormatter(formatter);  
			// the following statement is used to log any messages  
			logger.info(msg);
			fh.close();
		} catch (SecurityException e) {  
			e.printStackTrace();  
		} catch (IOException e) {  
			e.printStackTrace();  
		}  
	}
	// Convenience method, to extract a schedule object from an Argument.
	private static LogoSchedule getScheduleFromArguments(Argument args[], int index) throws ExtensionException, LogoException {
		Object obj = args[index].get();
		if (!(obj instanceof LogoSchedule)) {
			throw new ExtensionException("Was expecting a LogoSchedule as argument "+(index+1)+" found this instead: " + Dump.logoObject(obj));
		}
		return (LogoSchedule) obj;
	}
	private static void printToConsole(Context context, String msg) throws ExtensionException{
		try {
			ExtensionContext extcontext = (ExtensionContext) context;
			extcontext.workspace().outputObject(msg,null, true, true,OutputDestination.OUTPUT_AREA);
		} catch (LogoException e) {
			throw new ExtensionException(e);
		}
	}
	public static Context getContext() {
		return context;
	}
	public static void setContext(Context context) {
		TimeExtension.context = context;
	}
	/***********************
	 * Primitive Classes
	 ***********************/
	public static class NewLogoTime extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.StringType()},
					Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			TimeExtension.setContext(context); // for debugging
			LogoTime time = new LogoTime(getStringFromArgument(args, 0));
			return time;
		}
	}
	public static class CreateWithFormat extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.StringType(),Syntax.StringType()},
					Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			TimeExtension.setContext(context); // for debugging
			LogoTime time = new LogoTime(getStringFromArgument(args, 0),getStringFromArgument(args, 1));
			return time;
		}
	}
	public static class Anchor extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.NumberType(),Syntax.StringType()},
					Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime time = getTimeFromArgument(args, 0);
			LogoTime newTime = new LogoTime(time);
			newTime.setAnchor(getDoubleFromArgument(args, 1),
					stringToPeriodType(getStringFromArgument(args, 2)),
					((ExtensionContext)context).workspace().world());
			return newTime;
		}
	}
	public static class Show extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.StringType()},
					Syntax.StringType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime time = getTimeFromArgument(args, 0);
			String fmtString = getStringFromArgument(args, 1);
			DateTimeFormatter fmt = null;
			if(fmtString.trim().equals("")){
				fmt = DateTimeFormat.forPattern("yyyy-MM-dd HH:mm:ss.SSS");
			}else{
				fmt = DateTimeFormat.forPattern(fmtString);
			}
			return time.show(fmt);
		}
	}
	public static class Get extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.StringType(),Syntax.WildcardType()},
					Syntax.NumberType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			PeriodType periodType = stringToPeriodType(getStringFromArgument(args, 0));
			LogoTime time = getTimeFromArgument(args, 1);
			return time.get(periodType).doubleValue();
		}
	}
	public static class Copy extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType()},
					Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime time = getTimeFromArgument(args, 0);
			return new LogoTime(time);
		}
	}
	public static class Plus extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.NumberType(),Syntax.StringType()},
					Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime time = new LogoTime(getTimeFromArgument(args,0));
			return time.plus(stringToPeriodType(getStringFromArgument(args, 2)), getDoubleFromArgument(args, 1));
		}
	}
	public static class IsBefore extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType()},
					Syntax.BooleanType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime timeA = getTimeFromArgument(args,0);
			LogoTime timeB = getTimeFromArgument(args,1);
			return timeA.isBefore(timeB);
		}
	}
	public static class IsAfter extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType()},
					Syntax.BooleanType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime timeA = getTimeFromArgument(args,0);
			LogoTime timeB = getTimeFromArgument(args,1);
			return !(timeA.isBefore(timeB) || timeA.isEqual(timeB));
		}
	}
	public static class IsEqual extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType()},
					Syntax.BooleanType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime timeA = getTimeFromArgument(args,0);
			LogoTime timeB = getTimeFromArgument(args,1);
			return timeA.isEqual(timeB);
		}
	}
	public static class IsBetween extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType(),Syntax.WildcardType()},
					Syntax.BooleanType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime timeA = getTimeFromArgument(args,0);
			LogoTime timeB = getTimeFromArgument(args,1);
			LogoTime timeC = getTimeFromArgument(args,2);
			return timeA.isBetween(timeB,timeC);
		}
	}
	public static class DifferenceBetween extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType(),Syntax.StringType()},
					Syntax.NumberType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime startTime = getTimeFromArgument(args,0);
			LogoTime endTime = getTimeFromArgument(args,1);
			PeriodType pType = stringToPeriodType(getStringFromArgument(args, 2));
			return startTime.getDifferenceBetween(pType, endTime);
		}
	}
	public static class AnchorSchedule extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),Syntax.NumberType(),Syntax.StringType()});
		}
		public void perform(Argument args[], Context context)
				throws ExtensionException, LogoException {
			schedule.anchorSchedule(getTimeFromArgument(args, 0),getDoubleFromArgument(args, 1),stringToPeriodType(getStringFromArgument(args, 2)));
		}
	}
	public static class GetSize extends DefaultReporter {
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{},
					Syntax.NumberType());
		}
		public Object report(Argument args[], Context context)
				throws ExtensionException, LogoException {
			if(debug)printToConsole(context, "size of schedule: "+schedule.scheduleTree.size());
			return new Double(schedule.scheduleTree.size());
		}
	}
	public static class AddEvent extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.WildcardType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.addEvent(args,context,AddType.DEFAULT);
		}
	}
	public static class AddEventShuffled extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.WildcardType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.addEvent(args,context,AddType.SHUFFLE);
		}
	}
	public static class RepeatEventWithPeriod extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.NumberType(),
					Syntax.StringType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.addEvent(args,context,AddType.REPEAT);
		}
	}
	public static class RepeatEvent extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.NumberType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.addEvent(args,context,AddType.REPEAT);
		}
	}
	public static class RepeatEventShuffled extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.NumberType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.addEvent(args,context,AddType.SHUFFLE);
		}
	}
	public static class RepeatEventShuffledWithPeriod extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.WildcardType(),
					Syntax.NumberType(),
					Syntax.StringType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.addEvent(args,context,AddType.SHUFFLE);
		}
	}
	public static class ClearSchedule extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.clear();
		}
	}
	public static class Go extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			schedule.performScheduledTasks(args, context);
		}
	}
	public static class GoUntil extends DefaultCommand {
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTime untilTime = null;
			Double untilTick = null;
			try{
				untilTime = getTimeFromArgument(args, 0);
			}catch(ExtensionException e){
				untilTick = getDoubleFromArgument(args, 0);
			}
			if(untilTime == null){
				schedule.performScheduledTasks(args, context, untilTick);
			}else{
				schedule.performScheduledTasks(args, context, untilTime);
			}
		}
	}
	public static class TimeSeriesCreate extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoList columnList;
			try{
				columnList = getListFromArgument(args, 0);
			}catch(ExtensionException e){
				String colName = getStringFromArgument(args, 0);
				ArrayList<String> cols = new ArrayList<String>();
				cols.add(colName);
				columnList = LogoList.fromJava(cols);
			}
			LogoTimeSeries ts = new LogoTimeSeries(columnList);
			return ts;
		}
	}
	public static class TimeSeriesLoad extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.StringType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			String filename = getStringFromArgument(args, 0);
			LogoTimeSeries ts = new LogoTimeSeries(filename, (ExtensionContext) context);
			return ts;
		}
	}
	public static class TimeSeriesLoadWithFormat extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.StringType(),Syntax.StringType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			String filename = getStringFromArgument(args, 0);
			String format = getStringFromArgument(args, 1);
			LogoTimeSeries ts = new LogoTimeSeries(filename, format, (ExtensionContext) context);
			return ts;
		}
	}
	public static class TimeSeriesGet extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType(),Syntax.StringType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTimeSeries ts = getTimeSeriesFromArgument(args, 0);
			LogoTime time = getTimeFromArgument(args, 1);
			ts.ensureDateTypeConsistent(time);
			String columnName = getStringFromArgument(args, 2);
			if(columnName.equals("ALL") || columnName.equals("all")){
				columnName = "ALL_-_COLUMNS";
			}
			return ts.getByTime(time, columnName, GetTSMethod.NEAREST);
		}
	}
	public static class TimeSeriesGetExact extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType(),Syntax.StringType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTimeSeries ts = getTimeSeriesFromArgument(args, 0);
			LogoTime time = getTimeFromArgument(args, 1);
			ts.ensureDateTypeConsistent(time);
			String columnName = getStringFromArgument(args, 2);
			if(columnName.equals("ALL") || columnName.equals("all")){
				columnName = "ALL_-_COLUMNS";
			}
			return ts.getByTime(time, columnName, GetTSMethod.EXACT);
		}
	}
	public static class TimeSeriesGetInterp extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType(),Syntax.StringType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTimeSeries ts = getTimeSeriesFromArgument(args, 0);
			LogoTime time = getTimeFromArgument(args, 1);
			ts.ensureDateTypeConsistent(time);
			String columnName = getStringFromArgument(args, 2);
			if(columnName.equals("ALL") || columnName.equals("all")){
				columnName = "ALL_-_COLUMNS";
			}
			return ts.getByTime(time, columnName, GetTSMethod.LINEAR_INTERP);
		}
	}
	public static class TimeSeriesGetRange extends DefaultReporter{
		public Syntax getSyntax() {
			return Syntax.reporterSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType(),Syntax.WildcardType(),Syntax.StringType()},Syntax.WildcardType());
		}
		public Object report(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTimeSeries ts = getTimeSeriesFromArgument(args, 0);
			LogoTime timeA = getTimeFromArgument(args, 1);
			ts.ensureDateTypeConsistent(timeA);
			LogoTime timeB = getTimeFromArgument(args, 2);
			ts.ensureDateTypeConsistent(timeB);
			String columnName = getStringFromArgument(args, 3);
			if(columnName.equals("logotime")){
				columnName = "LOGOTIME";
			}
			if(columnName.equals("ALL") || columnName.equals("all")){
				columnName = "ALL_-_COLUMNS";
			}
			return ts.getRangeByTime(timeA, timeB, columnName);
		}
	}
	public static class TimeSeriesWrite extends DefaultCommand{
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),Syntax.StringType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTimeSeries ts = getTimeSeriesFromArgument(args, 0);
			String filename = getStringFromArgument(args, 1);
			ts.write(filename,(ExtensionContext)context);
		}
	}
	public static class TimeSeriesAddRow extends DefaultCommand{
		public Syntax getSyntax() {
			return Syntax.commandSyntax(new int[]{Syntax.WildcardType(),Syntax.WildcardType()});
		}
		public void perform(Argument args[], Context context) throws ExtensionException, LogoException {
			LogoTimeSeries ts = getTimeSeriesFromArgument(args, 0);
			LogoList list = getListFromArgument(args, 1);
			Object timeObj = list.get(0);
			LogoTime time = null;
			if (timeObj instanceof String) {
				time = new LogoTime(timeObj.toString());
			}else if (timeObj instanceof LogoTime) {
				// Create a new logotime since they are mutable
				time = new LogoTime((LogoTime)timeObj);
			}else{			
				throw new ExtensionException("time: was expecting a LogoTime object as the first item in the list passed as argument 2, found this instead: " + Dump.logoObject(timeObj));
			}
			if(list.size() != (ts.getNumColumns()+1)) throw new ExtensionException("time: cannot add "+(list.size()-1)+" values to a time series with "+ts.getNumColumns()+" columns.");
			ts.add(time,list.subList(1, list.size()));
		}
	}
}