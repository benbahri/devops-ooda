package fr.plb.calculator;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CalculatorController {

    /** Version affichée par /version : permet de voir un roll-out en direct (atelier 07). */
    private static final String VERSION = System.getenv().getOrDefault("APP_VERSION", "dev");

    private final CalculatorService service;

    public CalculatorController(CalculatorService service) {
        this.service = service;
    }

    @GetMapping("/add")
    public Map<String, Double> add(@RequestParam double a, @RequestParam double b) {
        return Map.of("result", service.add(a, b));
    }

    @GetMapping("/subtract")
    public Map<String, Double> subtract(@RequestParam double a, @RequestParam double b) {
        return Map.of("result", service.subtract(a, b));
    }

    @GetMapping("/multiply")
    public Map<String, Double> multiply(@RequestParam double a, @RequestParam double b) {
        return Map.of("result", service.multiply(a, b));
    }

    @GetMapping("/divide")
    public Map<String, Double> divide(@RequestParam double a, @RequestParam double b) {
        return Map.of("result", service.divide(a, b));
    }

    @GetMapping("/version")
    public Map<String, String> version() {
        return Map.of("version", VERSION);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> badRequest(IllegalArgumentException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", e.getMessage()));
    }
}
