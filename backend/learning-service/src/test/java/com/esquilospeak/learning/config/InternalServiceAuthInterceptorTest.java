package com.esquilospeak.learning.config;

import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

public class InternalServiceAuthInterceptorTest {

    @Test
    public void testTokenTooShort_ThrowsException() {
        InternalServiceAuthInterceptor interceptor = new InternalServiceAuthInterceptor();
        ReflectionTestUtils.setField(interceptor, "internalServiceToken", "short_token");
        assertThrows(IllegalStateException.class, interceptor::validateInternalServiceToken);
    }

    @Test
    public void testValidToken_AllowsRequest() throws Exception {
        InternalServiceAuthInterceptor interceptor = new InternalServiceAuthInterceptor();
        String validToken = "esquilospeak_internal_s2s_token_for_testing_32_bytes_long";
        ReflectionTestUtils.setField(interceptor, "internalServiceToken", validToken);

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("X-Internal-Service-Token", validToken);
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean result = interceptor.preHandle(request, response, new Object());
        assertTrue(result);
    }

    @Test
    public void testInvalidToken_BlocksRequest() throws Exception {
        InternalServiceAuthInterceptor interceptor = new InternalServiceAuthInterceptor();
        String validToken = "esquilospeak_internal_s2s_token_for_testing_32_bytes_long";
        ReflectionTestUtils.setField(interceptor, "internalServiceToken", validToken);

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("X-Internal-Service-Token", "invalid_token_123456789012345678901234567890");
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean result = interceptor.preHandle(request, response, new Object());
        assertFalse(result);
        assertEquals(HttpServletResponse.SC_FORBIDDEN, response.getStatus());
    }

    @Test
    public void testMissingToken_BlocksRequest() throws Exception {
        InternalServiceAuthInterceptor interceptor = new InternalServiceAuthInterceptor();
        String validToken = "esquilospeak_internal_s2s_token_for_testing_32_bytes_long";
        ReflectionTestUtils.setField(interceptor, "internalServiceToken", validToken);

        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean result = interceptor.preHandle(request, response, new Object());
        assertFalse(result);
        assertEquals(HttpServletResponse.SC_FORBIDDEN, response.getStatus());
    }
}
