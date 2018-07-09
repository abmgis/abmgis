/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */
import java.util.*;
import sim.util.*;
import sim.engine.*;

public class FieldUnit implements Valuable, java.io.Serializable {

    private int fieldID; // identify the type pf the field
    private int campID; // holds id of the three camps 
    private double water; // hold water amount
    private double elevation; // elevation 
    private boolean hasLatrine; // has laterine or not
    private double vibrioCholerae =0; // contamination level
    private int patientCounter =0;
    //public static final int ORDERING = 1;
    
    Facility facility; 
    
    int xLoc;
    int yLoc;
    
    
    private Bag refugeeHH ; // camp location for household
    private Bag refugee; // who are on the field right now
   
   
    
    // getter and setter
    public FieldUnit() {

        super();
        refugeeHH = new Bag();
         refugee = new Bag();
    }

    public FieldUnit(int x, int y) {
        this.setX(x);
        this.setY(y);

    }
    
    // check how many familes can occupied in a field
    public boolean isCampOccupied(Dadaab dadaab) {

        if (this.getRefugeeHH().size() >= dadaab.params.global.getMaximumHHOccumpancyPerField()) {
            return true;
        } else {
            return false;
        }
    }

    
    public void setRefugeeHH(Bag refugees) {

        this.refugeeHH = refugees;
    }

    public Bag getRefugeeHH() {

        return refugeeHH;
    }

    public void addRefugeeHH(Family r) {

        this.refugeeHH.add(r);
    }

    public void removeRefugeeHH(Family r) {

        this.refugeeHH.remove(r);
    }

    public void setRefugee(Bag refugeeMoving) {

        this.refugee = refugeeMoving;
    }

    public Bag getRefugee() {

        return refugee;
    }

    public void addRefugee(Refugee r) {

        this.refugee.add(r);
    }

    public void removeRefugee(Refugee r) {

        this.refugee.remove(r);
    }
    
    public void setFieldID(int id) {

        this.fieldID = id;
    }

    public int getFieldID() {

        return fieldID;
    }
    
    public void setCampID(int id) {

        this.campID = id;
    }

    public int getCampID() {

        return campID;
    }
    
    public void setFacility(Facility f){
        this.facility =f;
    }
    
    public Facility getFacility(){
        return facility;
    }
   
    
    public void setVibrioCholerae(double vc){
        this.vibrioCholerae = vc;
    }
    
    public double getVibrioCholerae(){
        return vibrioCholerae;
    }
  
    // water - either from borehole or rainfall
    public void setWater(double flow) {

        this.water = flow;
    }

    public double getWater() {

        return water;
    }
    
    
    public void setPatientCounter(int c){
        this.patientCounter = c;
    }
    
    public int getPatientCounter(){
        return patientCounter;
    }
    
    public void setElevation(double elev) {

        this.elevation = elev;
    }

    public double getElevation() {

        return elevation;
    }
   
    // is the field has latrine-  latrine is not personal but a shared one
    // ideal to make on the camp ratehr than at family level
    public void setCampHasLatrine(boolean l) {

        this.hasLatrine = l;
    }

    public boolean getCampHasLatrine() {

        return hasLatrine;
    }
    
    
   public boolean equals(FieldUnit b) {
        if (b.getX() == this.getX() && b.getY() == this.getY()) {
            return true;
        } else {
            return false;
        }
    }

    public boolean equals(int x, int y) {
        if (x == this.getX() && y == this.getY()) {
            return true;
        }
        return false;
    }
  // calaculate distance 
    public double distanceTo(FieldUnit b) {
        return Math.sqrt(Math.pow(b.getX() - this.getX(), 2) + Math.pow(b.getY() - this.getY(), 2));
    }

    public double distanceTo(int xCoord, int yCoord) {
        return Math.sqrt(Math.pow(xCoord - this.getX(), 2) + Math.pow(yCoord - this.getY(), 2));
    }

    FieldUnit copy() {
        FieldUnit l = new FieldUnit(this.getX(), this.getY());
        return l;
    }
    
   
   
    final public int getX() {
        return xLoc;
    }

    final public void setX(int x) {
        this.xLoc = x;
    }

    // location Y
    final public int getY() {
        return yLoc;
    }

    final public void setY(int y) {
        this.yLoc = y;
    }
    
   
    public double doubleValue() {

     return getCampID();
  

    }
}
