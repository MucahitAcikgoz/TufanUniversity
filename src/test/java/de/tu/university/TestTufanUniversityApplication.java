package de.tu.university;

import org.springframework.boot.SpringApplication;

public class TestTufanUniversityApplication {

    public static void main(String[] args) {
        SpringApplication.from(TufanUniversityApplication::main).with(TestcontainersConfiguration.class).run(args);
    }

}
