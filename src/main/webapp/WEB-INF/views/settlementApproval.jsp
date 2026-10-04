<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
    <title>Settlement Approval - Claim #<c:out value="${claim.claimId}"/></title>
</head>
<body>
<h1>Settlement Approval</h1>

<c:if test="${not empty errorMessage}">
    <div class="error" style="color:red;">
        <c:out value="${errorMessage}"/>
    </div>
</c:if>

<table>
    <tr>
        <th>Claim ID</th>
        <td><c:out value="${claim.claimId}"/></td>
    </tr>
    <tr>
        <th>Current Status</th>
        <td><c:out value="${claim.status}"/></td>
    </tr>
    <tr>
        <th>Calculated Payout Amount</th>
        <td>
            <c:if test="${not empty calculatedPayout}">
                <fmt:formatNumber value="${calculatedPayout}" type="currency" currencySymbol="$"/>
            </c:if>
            <c:if test="${empty calculatedPayout}">
                N/A
            </c:if>
        </td>
    </tr>
</table>

<h2>Approve Settlement</h2>
<form action="${pageContext.request.contextPath}/claims/${claim.claimId}/settlement/approve" method="post">
    <label for="approvedBy">Approved By:</label>
    <input type="text" id="approvedBy" name="approvedBy" value="" placeholder="system"/>
    <button type="submit">Approve Settlement</button>
</form>

</body>
</html>
