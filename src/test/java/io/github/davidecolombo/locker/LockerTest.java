package io.github.davidecolombo.locker;

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

class LockerTest {

    private static final String KEY = "test";
    private static final String PLAIN_TEXT = "The quick brown fox jumps over the lazy dog";
    private static final String FILE_NAME = System.getProperty("user.dir") + "/src/test/resources/AES_GCM_NoPadding.dat";

    @Test
    void shouldEncryptAndDecryptBytes() throws Exception {
        byte[] encryptedBytes = Locker.encrypt(PLAIN_TEXT.getBytes(StandardCharsets.UTF_8), KEY);
        byte[] decryptedBytes = Locker.decrypt(encryptedBytes, KEY);
        String decryptedText = new String(decryptedBytes);
        Assertions.assertEquals(PLAIN_TEXT, decryptedText);
    }

    @Test
    void shouldEncryptAndDecryptStream() throws Exception {

        // Encrypt plain-text to stream
        System.setIn(new ByteArrayInputStream(PLAIN_TEXT.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream encryptedByteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(encryptedByteArrayOutputStream));
        new Locker(new String[]{"--key", KEY,});
        byte[] encryptedBytes = encryptedByteArrayOutputStream.toByteArray();

        // Decrypt stream to plain-text
        System.setIn(new ByteArrayInputStream(encryptedBytes));
        ByteArrayOutputStream decryptedByteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(decryptedByteArrayOutputStream));
        new Locker(new String[]{"--key", KEY, "--decrypt"});
        byte[] decryptedBytes = decryptedByteArrayOutputStream.toByteArray();
        String decryptedText = new String(decryptedBytes);
        Assertions.assertEquals(PLAIN_TEXT, decryptedText);
    }

    @Test
    void shouldEncryptAndDecryptViaStdinPassphrase() throws Exception {
        byte[] passphraseBytes = KEY.getBytes(StandardCharsets.UTF_8);
        byte[] dataBytes = PLAIN_TEXT.getBytes(StandardCharsets.UTF_8);

        // Protocol: passphrase + '\n' + data
        byte[] encInput = new byte[passphraseBytes.length + 1 + dataBytes.length];
        System.arraycopy(passphraseBytes, 0, encInput, 0, passphraseBytes.length);
        encInput[passphraseBytes.length] = '\n';
        System.arraycopy(dataBytes, 0, encInput, passphraseBytes.length + 1, dataBytes.length);

        System.setIn(new ByteArrayInputStream(encInput));
        ByteArrayOutputStream encOut = new ByteArrayOutputStream();
        System.setOut(new PrintStream(encOut));
        new Locker(new String[]{});
        byte[] encrypted = encOut.toByteArray();

        byte[] decInput = new byte[passphraseBytes.length + 1 + encrypted.length];
        System.arraycopy(passphraseBytes, 0, decInput, 0, passphraseBytes.length);
        decInput[passphraseBytes.length] = '\n';
        System.arraycopy(encrypted, 0, decInput, passphraseBytes.length + 1, encrypted.length);

        System.setIn(new ByteArrayInputStream(decInput));
        ByteArrayOutputStream decOut = new ByteArrayOutputStream();
        System.setOut(new PrintStream(decOut));
        new Locker(new String[]{"--decrypt"});
        Assertions.assertEquals(PLAIN_TEXT, decOut.toString(StandardCharsets.UTF_8));
    }

    @Test
    void shouldDecryptFile() throws Exception {
        byte[] encryptedBytes = Files.readAllBytes(Paths.get(FILE_NAME));
        System.setIn(new ByteArrayInputStream(encryptedBytes));
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(byteArrayOutputStream));
        new Locker(new String[]{"--key", KEY, "--decrypt"});
        String decryptedText = byteArrayOutputStream.toString();
        Assertions.assertEquals(PLAIN_TEXT, decryptedText);
    }

    @Test
    void shouldThrowCmdLineException() {
        Assertions.assertThrows(CmdLineException.class,
                () -> new Locker(new String[]{"--invalid"}));
    }

    @Test
    void shouldThrowIllegalArgumentException() {
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> new Locker(new String[]{"--key", ""}));
        // zero-length passphrase via stdin protocol: just a newline
        System.setIn(new ByteArrayInputStream(new byte[]{'\n'}));
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> new Locker(new String[]{}));
    }

    @Test
    void shouldThrowAEADBadTagException() throws Exception {
        byte[] encryptedBytes = Files.readAllBytes(Paths.get(FILE_NAME));
        System.setIn(new ByteArrayInputStream(encryptedBytes));
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        System.setOut(new PrintStream(byteArrayOutputStream));
        Assertions.assertThrows(AEADBadTagException.class,
                () -> new Locker(new String[]{"--key", "wrong_key", "--decrypt"}));
    }

    @Test
    void shouldThrowNullPointerException() {
        Assertions.assertThrows(NullPointerException.class,
                () -> new Locker(null));
        Assertions.assertThrows(NullPointerException.class,
                () -> new Locker(new String[]{"--key", null}));
    }

    @Test
    void shouldThrowIllegalArgumentExceptionForShortInput() {
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> Locker.decrypt(new byte[10], KEY));
    }

    @Test
    void shouldEncryptViaMain() throws Exception {
        System.setIn(new ByteArrayInputStream(PLAIN_TEXT.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        System.setOut(new PrintStream(out));
        Locker.main(new String[]{"--key", KEY});
        Assertions.assertTrue(out.size() > 0);
    }
}
