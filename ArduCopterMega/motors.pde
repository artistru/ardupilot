
#define ARM_DELAY 10
#define DISARM_DELAY 10

void arm_motors()
{
	static byte arming_counter;

	// Arm motor output : Throttle down and full yaw right for more than 2 seconds
	if (rc_3.control_in == 0){		
		if (rc_4.control_in > 2700) {
			if (arming_counter > ARM_DELAY) {
				motor_armed = true;
			} else{
				arming_counter++;
			}
		}else if (rc_4.control_in < -2700) {
			if (arming_counter > DISARM_DELAY){
				motor_armed = false;
			}else{
				arming_counter++;
			}			
		}else{
			arming_counter = 0;
		}
	}
}




/*****************************************
 * Set the flight control servos based on the current calculated values
 *****************************************/
void 
set_servos_4()
{
	static byte num;
	static byte counteri;

	// Quadcopter mix
	if (motor_armed == true && motor_auto_safe == true) {
		int out_min = rc_3.radio_min;
		
		// Throttle is 0 to 1000 only
		rc_3.servo_out 	= constrain(rc_3.servo_out, 0, 1000);	

		if(rc_3.servo_out > 0)
			out_min = rc_3.radio_min + 50;
			
		//Serial.printf("out: %d %d %d %d\t\t", rc_1.servo_out, rc_2.servo_out, rc_3.servo_out, rc_4.servo_out);
		
		// creates the radio_out and pwm_out values
		rc_1.calc_pwm();
		rc_2.calc_pwm();
		rc_3.calc_pwm();
		rc_4.calc_pwm();

		//Serial.printf("out: %d %d %d %d\n", rc_1.radio_out, rc_2.radio_out, rc_3.radio_out, rc_4.radio_out);
		//Serial.printf("yaw: %d ", rc_4.radio_out);
		
		if(frame_type == PLUS_FRAME){

			motor_out[CH_1]		= rc_3.radio_out - rc_1.pwm_out;
			motor_out[CH_2]		= rc_3.radio_out + rc_1.pwm_out;
			motor_out[CH_3]		= rc_3.radio_out + rc_2.pwm_out;
			motor_out[CH_4] 	= rc_3.radio_out - rc_2.pwm_out;
			
			motor_out[CH_1]		+=  rc_4.pwm_out; 	// CCW
			motor_out[CH_2]		+=  rc_4.pwm_out; 	// CCW
			motor_out[CH_3]		-=  rc_4.pwm_out; 	// CW
			motor_out[CH_4] 	-=  rc_4.pwm_out; 	// CW
			
			
		}else if(frame_type == X_FRAME){
		
			int roll_out 	 	= rc_1.pwm_out / 2;
			int pitch_out 	 	= rc_2.pwm_out / 2;

			motor_out[CH_3]	 	= rc_3.radio_out + roll_out + pitch_out;
			motor_out[CH_2]	 	= rc_3.radio_out + roll_out - pitch_out;

			motor_out[CH_1]		= rc_3.radio_out - roll_out + pitch_out;
			motor_out[CH_4] 	= rc_3.radio_out - roll_out - pitch_out;
			
			//Serial.printf("\tb4: %d %d %d %d ", motor_out[CH_1], motor_out[CH_2], motor_out[CH_3], motor_out[CH_4]);		
			
			motor_out[CH_1]		+= rc_4.pwm_out;	// CCW
			motor_out[CH_2]		+= rc_4.pwm_out;	// CCW
			motor_out[CH_3]		-= rc_4.pwm_out;	// CW
			motor_out[CH_4] 	-= rc_4.pwm_out;	// CW
			
			//Serial.printf("\tl8r: %d %d %d %d\n", motor_out[CH_1], motor_out[CH_2], motor_out[CH_3], motor_out[CH_4]);
				
		}else if(frame_type == TRI_FRAME){

			// Tri-copter power distribution
			
			int roll_out 		= (float)rc_1.pwm_out * .866;
			int pitch_out 		= rc_2.pwm_out / 2;
			
			// front two motors
			motor_out[CH_2]		= rc_3.radio_out + roll_out + pitch_out;
			motor_out[CH_1]		= rc_3.radio_out - roll_out + pitch_out;
			
			// rear motors
			motor_out[CH_4] 	= rc_3.radio_out - rc_2.pwm_out;
			
			// servo Yaw
			//motor_out[CH_3] 	= rc_4.radio_out;
			APM_RC.OutputCh(CH_7, rc_4.radio_out);

			
		}else if (frame_type == HEXA_FRAME) {

			int roll_out 		= (float)rc_1.pwm_out * .866;
			int pitch_out 		= rc_2.pwm_out / 2;

			//left side			
			motor_out[CH_2]		= rc_3.radio_out + rc_1.pwm_out;          // CCW
			motor_out[CH_3]		= rc_3.radio_out + roll_out + pitch_out;  // CW
			motor_out[CH_8]     = rc_3.radio_out + roll_out - pitch_out;  // CW

			//right side			
			motor_out[CH_1]		= rc_3.radio_out - rc_1.pwm_out;          // CW
            motor_out[CH_7] 	= rc_3.radio_out - roll_out + pitch_out;  // CCW
			motor_out[CH_4] 	= rc_3.radio_out - roll_out - pitch_out;  // CCW

            motor_out[CH_7]		+= rc_4.pwm_out;	// CCW
			motor_out[CH_2]		+= rc_4.pwm_out;	// CCW
			motor_out[CH_4] 	+= rc_4.pwm_out;	// CCW

			motor_out[CH_3]		-= rc_4.pwm_out;	// CW
			motor_out[CH_1]		-= rc_4.pwm_out;	// CW
			motor_out[CH_8]     -= rc_4.pwm_out;  	// CW
			
    	} else {
		
			Serial.print("frame error");
			
		}
		

		motor_out[CH_1]		= constrain(motor_out[CH_1], 	out_min, rc_3.radio_max);
		motor_out[CH_2]		= constrain(motor_out[CH_2], 	out_min, rc_3.radio_max);
		motor_out[CH_3]		= constrain(motor_out[CH_3], 	out_min, rc_3.radio_max);
		motor_out[CH_4] 	= constrain(motor_out[CH_4], 	out_min, rc_3.radio_max);
				
		if (frame_type == HEXA_FRAME) {
			motor_out[CH_7]		= constrain(motor_out[CH_7], 	out_min, rc_3.radio_max);
			motor_out[CH_8]		= constrain(motor_out[CH_8], 	out_min, rc_3.radio_max);
		}
		
		num++;
		if (num > 10){
			num = 0;
			//Serial.print("!");
			//debugging with Channel 6
			
			//pid_baro_throttle.kD((float)rc_6.control_in / 1000); //  0 to 1

			/*
			// ROLL and PITCH 
			// make sure you init_pids() after changing the kP
			pid_stabilize_roll.kP((float)rc_6.control_in / 1000);
			init_pids();
			//Serial.print("kP: ");
			//Serial.println(pid_stabilize_roll.kP(),3);
			*/

			/*
			// YAW
			// make sure you init_pids() after changing the kP
			pid_yaw.kP((float)rc_6.control_in / 1000);
			init_pids();
			*/			
		}
		
		// Send commands to motors
		if(rc_3.servo_out > 0){
		
			APM_RC.OutputCh(CH_1, motor_out[CH_1]);
			APM_RC.OutputCh(CH_2, motor_out[CH_2]);
			APM_RC.OutputCh(CH_3, motor_out[CH_3]);
			APM_RC.OutputCh(CH_4, motor_out[CH_4]);
			// InstantPWM
			APM_RC.Force_Out0_Out1();
			APM_RC.Force_Out2_Out3();

			if (frame_type == HEXA_FRAME) {
				APM_RC.OutputCh(CH_7, motor_out[CH_7]);
				APM_RC.OutputCh(CH_8, motor_out[CH_8]);
				APM_RC.Force_Out6_Out7();
			}
			
		}else{
		
			APM_RC.OutputCh(CH_1, rc_3.radio_min);
			APM_RC.OutputCh(CH_2, rc_3.radio_min);
			APM_RC.OutputCh(CH_3, rc_3.radio_min);
			APM_RC.OutputCh(CH_4, rc_3.radio_min);
			// InstantPWM
			APM_RC.Force_Out0_Out1();
			APM_RC.Force_Out2_Out3();

			if (frame_type == HEXA_FRAME) {
				APM_RC.OutputCh(CH_7, rc_3.radio_min);
				APM_RC.OutputCh(CH_8, rc_3.radio_min);
				APM_RC.Force_Out6_Out7();
			}
		}
		
	}else{
		num++;
		if (num > 10){
			num = 0;
			//Serial.print("-");
		}
		
		reset_I();
		
		if(rc_3.control_in > 0){
			// we have pushed up the throttle
			// remove safety
			motor_auto_safe = true;
		}
		
		// Send commands to motors
		APM_RC.OutputCh(CH_1, rc_3.radio_min);
		APM_RC.OutputCh(CH_2, rc_3.radio_min);
		APM_RC.OutputCh(CH_3, rc_3.radio_min);
		APM_RC.OutputCh(CH_4, rc_3.radio_min);

		if (frame_type == HEXA_FRAME) {
			APM_RC.OutputCh(CH_7, rc_3.radio_min);
			APM_RC.OutputCh(CH_8, rc_3.radio_min);
		}
		
		// reset I terms of PID controls
		reset_I();
		
		// Initialize yaw command to actual yaw when throttle is down...
		rc_4.control_in = ToDeg(yaw);
	}
 }
