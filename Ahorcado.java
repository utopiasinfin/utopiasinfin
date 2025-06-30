import java.util.Scanner;

public class aAhorcado {

    // ANSI escape codes for colors
    public static final String RESET = "\u001B[0m";
    public static final String RED = "\u001B[31m";
    public static final String GREEN = "\u001B[32m";
    public static final String YELLOW = "\u001B[33m";

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        String secretWord = "intelligence";
        int maxAttempts = 10;
        int attempts = 0;
        boolean wordGuessed = false;

        char[] guessedLetters = new char[secretWord.length()];
        for (int i = 0; i < guessedLetters.length; i++) {
            guessedLetters[i] = '_';
        }

        System.out.println(YELLOW + "=== Welcome to the Hangman Game ===" + RESET);

        while (!wordGuessed && attempts < maxAttempts) {
            System.out.println("\nCurrent word: " + String.valueOf(guessedLetters));
            System.out.print("Please enter a letter: ");
            char letter = scanner.next().toLowerCase().charAt(0);

            boolean correctLetter = false;

            for (int i = 0; i < secretWord.length(); i++) {
                if (secretWord.charAt(i) == letter) {
                    guessedLetters[i] = letter;
                    correctLetter = true;
                }
            }

            if (correctLetter) {
                System.out.println(GREEN + "Correct!" + RESET);
            } else {
                attempts++;
                System.out.println(RED + "Incorrect! You have " + (maxAttempts - attempts) + " attempts left." + RESET);
            }

            if (String.copyValueOf(guessedLetters).equals(secretWord)) {
                wordGuessed = true;
                System.out.println(GREEN + "Congratulations! You guessed the word: " + secretWord + RESET);
            }
        }

        if (!wordGuessed) {
            System.out.println(RED + "Game over. The secret word was: " + secretWord + RESET);
        }

        scanner.close();
    }
}
