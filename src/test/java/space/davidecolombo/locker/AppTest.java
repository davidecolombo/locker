package space.davidecolombo.locker;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.kohsuke.args4j.CmdLineException;

import javax.crypto.AEADBadTagException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

class AppTest {

    private static final String KEY = "test";
    private static final String PLAIN_TEXT = "The quick brown fox jumps over the lazy dog";
    private static final String FILE_NAME = System.getProperty("user.dir") + "/src/test/resources/AES_GCM_NoPadding.dat";

    @Test
    void shouldEncryptAndDecryptBytes() throws Exception {
        byte[] encryptedBytes = App.encrypt(PLAIN_TEXT.getBytes(StandardCharsets.UTF_8), KEY);
        // Files.write(Paths.get(FILE_NAME), encryptedBytes);
        byte[] decryptedBytes = App.decrypt(encryptedBytes, KEY);
        String decryptedText = new String(decryptedBytes);
        Assertions.assertEquals(PLAIN_TEXT, decryptedText);
    }

    @Test
    void shouldEncryptAndDecryptStream() throws Exception {

        // Encrypt plain-text to stream
        System.setIn(new ByteArrayInputStream(PLAIN_TEXT.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream encryptedByteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(encryptedByteArrayOutputStream));
        new App(new String[]{"--key", KEY,});
        byte[] encryptedBytes = encryptedByteArrayOutputStream.toByteArray();

        // Decrypt stream to plain-text
        System.setIn(new ByteArrayInputStream(encryptedBytes));
        ByteArrayOutputStream decryptedByteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(decryptedByteArrayOutputStream));
        new App(new String[]{"--key", KEY, "--decrypt"});
        byte[] decryptedBytes = decryptedByteArrayOutputStream.toByteArray();
        String decryptedText = new String(decryptedBytes);
        Assertions.assertEquals(PLAIN_TEXT, decryptedText);
    }

    @Test
    void shouldDecryptFile() throws Exception {
        byte[] encryptedBytes = Files.readAllBytes(Paths.get(FILE_NAME));
        System.setIn(new ByteArrayInputStream(encryptedBytes));
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(byteArrayOutputStream));
        new App(new String[]{"--key", KEY, "--decrypt"});
        String decryptedText = byteArrayOutputStream.toString();
        Assertions.assertEquals(PLAIN_TEXT, decryptedText);
    }

    @Test
    void shouldThrowCmdLineException() {
        Assertions.assertThrows(CmdLineException.class,
                () -> new App(new String[]{}));
        Assertions.assertThrows(CmdLineException.class,
                () -> new App(new String[]{"--invalid"}));
    }

    @Test
    void shouldThrowIllegalArgumentException() {
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> new App(new String[]{"--key", ""}));
    }

    @Test
    void shouldThrowAEADBadTagException() throws Exception {
        byte[] encryptedBytes = Files.readAllBytes(Paths.get(FILE_NAME));
        System.setIn(new ByteArrayInputStream(encryptedBytes));
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(byteArrayOutputStream));
        Assertions.assertThrows(AEADBadTagException.class,
                () -> new App(new String[]{"--key", "wrong_key", "--decrypt"}));
    }

    @Test
    void shouldThrowNullPointerException() {
        Assertions.assertThrows(NullPointerException.class,
                () -> new App(null));
        Assertions.assertThrows(NullPointerException.class,
                () -> new App(new String[]{"--key", null}));
    }
}