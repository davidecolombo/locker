package space.davidecolombo.locker;

import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;

@SuppressWarnings({"java:S112", "java:S6212"})
public class App {

    private static final String CIPHER_TRANSFORMATION = "AES/GCM/NoPadding";
    private static final String MESSAGE_DIGEST_ALGORITHM = "SHA-256";
    private static final String SECRET_KEY_ALGORITHM = "AES";
    private static final String RNG_ALGORITHM = "SHA1PRNG";
    private static final int KEY_SIZE = 32;

    @Option(name = "--key", aliases = {"-k"}, required = true)
    private String key;

    @Option(name = "--decrypt", aliases = {"-d"})
    private boolean decrypt;

    public static byte[] encrypt(byte[] clean, String key) throws Exception {
        Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);

        // Generating IV
        int blockSize = cipher.getBlockSize();
        byte[] iv = new byte[blockSize];
        SecureRandom.getInstance(RNG_ALGORITHM).nextBytes(iv);
        GCMParameterSpec parameterSpec = new GCMParameterSpec(blockSize * Byte.SIZE, iv);

        // Hashing key
        MessageDigest messageDigest = MessageDigest.getInstance(MESSAGE_DIGEST_ALGORITHM);
        messageDigest.update(key.getBytes(StandardCharsets.UTF_8));
        byte[] keyBytes = new byte[KEY_SIZE];
        System.arraycopy(messageDigest.digest(), 0, keyBytes, 0, keyBytes.length);
        SecretKeySpec secretKeySpec = new SecretKeySpec(keyBytes, SECRET_KEY_ALGORITHM);

        // Encrypt
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec, parameterSpec);
        byte[] encrypted = cipher.doFinal(clean);

        // Combine IV and encrypted part
        byte[] encryptedIVAndText = new byte[blockSize + encrypted.length];
        System.arraycopy(iv, 0, encryptedIVAndText, 0, blockSize);
        System.arraycopy(encrypted, 0, encryptedIVAndText, blockSize, encrypted.length);

        return encryptedIVAndText;
    }

    public static byte[] decrypt(byte[] encryptedIvTextBytes, String key) throws Exception {
        Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
        int blockSize = cipher.getBlockSize();

        // Extract IV
        byte[] iv = new byte[blockSize];
        System.arraycopy(encryptedIvTextBytes, 0, iv, 0, iv.length);
        GCMParameterSpec ivParameterSpec = new GCMParameterSpec(blockSize * Byte.SIZE, iv);

        // Extract encrypted part
        int encryptedSize = encryptedIvTextBytes.length - blockSize;
        byte[] encryptedBytes = new byte[encryptedSize];
        System.arraycopy(encryptedIvTextBytes, blockSize, encryptedBytes, 0, encryptedSize);

        // Hash key
        byte[] keyBytes = new byte[KEY_SIZE];
        MessageDigest messageDigest = MessageDigest.getInstance(MESSAGE_DIGEST_ALGORITHM);
        messageDigest.update(key.getBytes());
        System.arraycopy(messageDigest.digest(), 0, keyBytes, 0, keyBytes.length);
        SecretKeySpec secretKeySpec = new SecretKeySpec(keyBytes, SECRET_KEY_ALGORITHM);

        // Decrypt
        cipher.init(Cipher.DECRYPT_MODE, secretKeySpec, ivParameterSpec);
        return cipher.doFinal(encryptedBytes);
    }

    @SuppressWarnings("java:S106")
    public App(String[] args) throws Exception {
        new CmdLineParser(this).parseArgument(args);
        if (key.length() == 0) {
            throw new IllegalArgumentException();
        }
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        int size = 256;
        byte[] buffer = new byte[size];
        try (InputStream is = System.in) {
            int len;
            while ((len = is.read(buffer, 0, size)) != -1) {
                stream.write(buffer, 0, len);
            }
        }
        System.out.write(decrypt
                ? decrypt(stream.toByteArray(), key)
                : encrypt(stream.toByteArray(), key));
    }

    public static void main(String[] args) throws Exception {
        new App(args);
    }
}