package com.esquilospeak.content.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.esquilospeak.content.domain.*;
import com.esquilospeak.content.infrastructure.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.List;

@Component
public class ContentDatabaseInitializer implements CommandLineRunner {

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private UnitRepository unitRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ResourceLoader resourceLoader;

    @Override
    public void run(String... args) throws Exception {
        if (courseRepository.count() == 0) {
            System.out.println("[Content-Service] Starting Database seeding...");

            // 1. Seed Course
            Resource courseResource = resourceLoader.getResource("classpath:seed/course.json");
            try (InputStream is = courseResource.getInputStream()) {
                Course course = objectMapper.readValue(is, Course.class);
                courseRepository.save(course);
                System.out.println("[Content-Service] Seeded Course: " + course.getCourseId());
            }

            // 2. Seed Units
            Resource unitsResource = resourceLoader.getResource("classpath:seed/units.json");
            try (InputStream is = unitsResource.getInputStream()) {
                List<Unit> units = objectMapper.readValue(is, new TypeReference<List<Unit>>() {});
                unitRepository.saveAll(units);
                System.out.println("[Content-Service] Seeded " + units.size() + " Units");
            }

            // 3. Seed Lessons
            Resource lessonsResource = resourceLoader.getResource("classpath:seed/lessons.json");
            try (InputStream is = lessonsResource.getInputStream()) {
                List<Lesson> lessons = objectMapper.readValue(is, new TypeReference<List<Lesson>>() {});
                lessonRepository.saveAll(lessons);
                System.out.println("[Content-Service] Seeded " + lessons.size() + " Lessons");
            }

            // 4. Seed Questions
            Resource questionsResource = resourceLoader.getResource("classpath:seed/questions.json");
            try (InputStream is = questionsResource.getInputStream()) {
                List<Question> questions = objectMapper.readValue(is, new TypeReference<List<Question>>() {});
                questionRepository.saveAll(questions);
                System.out.println("[Content-Service] Seeded " + questions.size() + " Questions");
            }

            System.out.println("[Content-Service] Database seeding completed successfully!");
        } else {
            System.out.println("[Content-Service] Database already contains data. Seeding skipped.");
        }
    }
}
