package fr.plb.calculator;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class CalculatorServiceTest {

    private final CalculatorService service = new CalculatorService();

    @Test
    void addition() {
        assertEquals(5.0, service.add(2, 3));
    }

    @Test
    void soustraction() {
        assertEquals(-1.0, service.subtract(2, 3));
    }

    @Test
    void multiplication() {
        assertEquals(6.0, service.multiply(2, 3));
    }

    @Test
    void division() {
        assertEquals(2.5, service.divide(5, 2));
    }

    @Test
    void divisionParZeroEstRefusee() {
        assertThrows(IllegalArgumentException.class, () -> service.divide(1, 0));
    }
}
