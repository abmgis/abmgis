package kibera;

import kibera.Resident.Gender;
import sim.util.Bag;

public class Business {
	
	/*
	 * Each business has a capacity for the number of employees it can hire
	 */
	
	/** The employees working at the business */
	private Bag employees;
	public Bag getEmployees() { return employees; }
	public void addEmployee(Resident val) { employees.add(val); }
	public void removeEmployee(Resident val) { employees.remove(val); }

	private Structure structure;
	public Structure getStructure() { return structure; }
	public void setStructure(Structure val) { structure = val; }
	
	/** Identifies whether the business is formal or informal */
	//public enum BusinessType { formal, informal };
	//kibera.BusinessType businessType;
	//public BusinessType getBusienssType() { return businessType; }
	//public void setBusinessType(BusinessType val) { businessType = val; }
	
	/** The capacity of employees working at the business */
	private int employeeCapacity;
	public double getEmployeeCapacity() { return employeeCapacity; }
	public void setEmployeeCapacity(int val) { employeeCapacity = val; }
	
	public Business(Structure s) {
		employees = new Bag();
	}
	
	//has capacity been reached
	public boolean isEmployeeCapacityReached() {

			int numEmployees = employees.size();
		
			if (numEmployees == getEmployeeCapacity()) {
				return true;
			}
			else { return false; }
	}
}
