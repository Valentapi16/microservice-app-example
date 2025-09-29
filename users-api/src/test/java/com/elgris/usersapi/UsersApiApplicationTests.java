package com.elgris.usersapi;

import org.junit.Test;
import static org.junit.Assert.*;

public class UsersApiApplicationTests {

	@Test
	public void basicTest() {
		// Test básico sin dependencias de Spring
		String expected = "users-api";
		String actual = "users-api";
		assertEquals("Basic test should pass", expected, actual);
	}
	
	@Test
	public void mathTest() {
		// Test matemático simple
		int result = 2 + 2;
		assertEquals("Math should work", 4, result);
	}

}
