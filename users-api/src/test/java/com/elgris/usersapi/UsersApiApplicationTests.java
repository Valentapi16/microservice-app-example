package com.elgris.usersapi;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "spring.sleuth.enabled=false",
    "spring.sleuth.zipkin.enabled=false",
    "spring.datasource.url=jdbc:h2:mem:testdb",
    "jwt.secret=test-secret"
})
public class UsersApiApplicationTests {

	@Test
	public void contextLoads() {
		// Test básico para verificar que el contexto se carga correctamente
		assert(true);
	}

}
