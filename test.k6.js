import { check } from 'k6';
import http from 'k6/http';

export const options = {
  // Key configurations for Stress in this section
  stages: [
    { duration: '5s', target: 50 }, // traffic ramp-up from 1 to a higher 200 users over 10 minutes.
    { duration: '50s', target: 50 }, // stay at higher 200 users for 30 minutes
    { duration: '5s', target: 0 }, // ramp-down to 0 users
  ],
};

export default function () {
  const res = http.get(`http://localhost:8000/testroute?some=${Math.floor(Math.random() * 10000)}`);
  check(res, {
    'is status 200': (r) => r.status === 200,
  });
  check(res, {
    'is cache hit': (r) => r.headers['X-Cache-Status'] && r.headers['X-Cache-Status'].toLowerCase() == "hit",
  });
  check(res, {
    'is cache miss': (r) => r.headers['X-Cache-Status'] && r.headers['X-Cache-Status'].toLowerCase() == "miss",
  });
}